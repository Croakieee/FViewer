import json, sys

schema = json.load(open(sys.argv[1]))
catalog_path, defaults_path = sys.argv[2], sys.argv[3]
catalog = json.load(open(catalog_path))
fixed = {
    'AvfxCurveColor': 'Col', 'AvfxLife': 'Life', 'AvfxParticleSimple': 'Smpl', 'AvfxParticleTextureColor1': 'TC1',
    'AvfxParticleTextureNormal': 'TN', 'AvfxParticleTextureReflection': 'TR', 'AvfxParticleTextureDistortion': 'TD',
    'AvfxParticleTexturePalette': 'TP', 'AvfxBinderPropertiesName': 'Name', 'AvfxCurveKeys': 'Keys', 'AvfxSimpleColors': 'Cols',
    'AvfxSimpleFrames': 'Frms', 'AvfxEmitVertexNumbers': 'VNum', 'AvfxEmitVertexes': 'VEmt', 'AvfxVertexes': 'VDrw', 'AvfxIndexes': 'VIdx',
}
types = {'AvfxEmitter': ('EVT', 'EmitterType'), 'AvfxParticle': ('PrVT', 'ParticleType'), 'AvfxEffector': ('EfVT', 'EffectorType'),
         'AvfxBinder': ('BnVr', 'BinderType')}
classes, defaults, sizes, optional, angles = {}, {}, {}, [], {}
for name, info in schema.items():
    rows = []
    for field in info['fields']:
        if field.get('unresolved'):
            if field['field'] == 'Type' and name in types:
                rows.append([types[name][0], 'Type', 'AvfxEnum<%s>' % types[name][1]])
            continue
        base = field['type'].split('<')[0]
        tag = field.get('tag')
        if base in fixed and field.get('single'):
            tag = fixed[base]
        if not tag:
            continue
        rows.append([tag, field.get('name', tag), field['type']])
        if 'default' in field:
            defaults.setdefault(name, {})[tag] = field['default']
        if 'size' in field:
            sizes.setdefault(name, {})[tag] = field['size']
        if field.get('angle'):
            angles.setdefault(name, []).append(tag)
    classes[name] = rows
    if info['optional']:
        optional.append(name)
for name, rows in catalog['classes'].items():
    if name not in classes:
        classes[name] = rows
catalog['classes'] = classes
json.dump(catalog, open(catalog_path, 'w'), indent=1, sort_keys=True)
json.dump({'defaults': defaults, 'sizes': sizes, 'optional': sorted(optional), 'angles': angles}, open(defaults_path, 'w'), indent=1, sort_keys=True)
print(len(classes), 'classes', sum(len(v) for v in classes.values()), 'fields', len(optional), 'optional')
