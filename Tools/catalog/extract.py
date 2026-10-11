import glob, json, re, sys

root = sys.argv[1]
old = json.load(open(sys.argv[2]))
enums = {k: {n: v for n, v in vals} for k, vals in old['enums'].items()}

def strip_comments(text):
    text = re.sub(r'/\*.*?\*/', '', text, flags=re.S)
    return re.sub(r'//[^\n]*', '', text)

def match_brace(text, start):
    depth = 0
    for i in range(start, len(text)):
        if text[i] == '{':
            depth += 1
        elif text[i] == '}':
            depth -= 1
            if depth == 0:
                return i
    return len(text)

def split_args(text):
    out, depth, cur, quote = [], 0, '', False
    for ch in text:
        if ch == '"':
            quote = not quote
        if not quote:
            if ch in '([{<':
                depth += 1
            elif ch in ')]}>':
                depth -= 1
            elif ch == ',' and depth == 0:
                out.append(cur.strip())
                cur = ''
                continue
        cur += ch
    if cur.strip():
        out.append(cur.strip())
    return out

def value_of(raw):
    raw = raw.strip()
    if raw in ('true', 'false'):
        return 1 if raw == 'true' else 0
    if re.match(r'^-?(0x[0-9a-fA-F]+|\d+)$', raw):
        return int(raw, 0)
    if re.match(r'^-?\d+(\.\d+)?f?$', raw):
        return float(raw.rstrip('f'))
    parts = raw.split('.')
    if len(parts) >= 2:
        return enums.get(parts[-2], {}).get(parts[-1])
    return None

classes = {}
for path in sorted(glob.glob(root + '/**/*.cs', recursive=True)):
    text = strip_comments(open(path, encoding='utf-8', errors='ignore').read())
    for m in re.finditer(r'\bclass\s+(\w+)(?:<[^>]*>)?\s*(?::\s*([^{]*))?\{', text):
        name, bases = m.group(1), (m.group(2) or '')
        end = match_brace(text, m.end() - 1)
        body = text[m.end():end]
        fields = {}
        for f in re.finditer(r'(?:public|private|protected)\s+(?:readonly\s+)?([\w<>\?]+)\s+(\w+)\s*(?:=\s*new(?:\s+[\w<>]+)?\s*\((.*?)\)\s*)?;', body, flags=re.S):
            ftype, fname, args = f.group(1), f.group(2), f.group(3)
            if not ftype.startswith('Avfx'):
                continue
            fields[fname] = {'type': ftype, 'args': args}
        for f in re.finditer(r'\b(\w+)\s*=\s*new(?:\s+[\w<>]+)?\s*\((.*?)\)\s*;', body, flags=re.S):
            fname, args = f.group(1), f.group(2)
            if fname in fields and fields[fname]['args'] is None:
                fields[fname]['args'] = args
        order = []
        for p in re.finditer(r'\b(Parsed\d?)\s*=\s*\[(.*?)\]\s*;', body, flags=re.S):
            order.append((p.group(1), [x.strip() for x in p.group(2).split(',') if x.strip()]))
        if not order:
            continue
        out = []
        for listName, names in order:
            for fname in names:
                info = fields.get(fname)
                if not info or info['args'] is None:
                    out.append({'field': fname, 'list': listName, 'unresolved': True})
                    continue
                args = split_args(info['args'])
                strings = []
                for a in args:
                    plain = re.sub(r'^(name|avfxName)\s*:\s*', '', a)
                    if plain.startswith('"') and plain.endswith('"'):
                        strings.append(plain[1:-1])
                entry_single = len(strings) == 1
                entry = {'field': fname, 'list': listName, 'type': info['type']}
                if len(strings) >= 2:
                    entry['name'], entry['tag'] = strings[0], strings[1]
                elif len(strings) == 1:
                    entry['name'], entry['tag'] = strings[0], strings[0]
                    entry['single'] = True
                for a in args:
                    v = re.match(r'value:\s*(.+)$', a)
                    if v and value_of(v.group(1)) is not None:
                        entry['default'] = value_of(v.group(1))
                    s = re.match(r'size:\s*(\d+)$', a)
                    if s:
                        entry['size'] = int(s.group(1))
                    if 'CurveType.Angle' in a:
                        entry['angle'] = True
                    if 'CurveType.Color' in a:
                        entry['color'] = True
                positional = [a for a in args if not a.startswith('"') and ':' not in a]
                if info['type'].startswith('AvfxBool') and positional and positional[0] in ('true', 'false') and 'default' not in entry:
                    entry['default'] = 1 if positional[0] == 'true' else 0
                    if len(positional) > 1 and positional[1].isdigit():
                        entry['size'] = int(positional[1])
                elif info['type'].startswith('AvfxBool') and positional and positional[0].isdigit():
                    entry['size'] = int(positional[0])
                out.append(entry)
        optional = bool(re.search(r'public\s+' + name + r'\s*\([^)]*\)\s*:\s*base\(\s*true\s*\)', body))
        classes[name] = {'bases': bases.strip(), 'optional': optional, 'fields': out, 'file': path.split('AvfxFormat/')[-1]}

json.dump(classes, open(sys.argv[3], 'w'), indent=1)
unresolved = [(c, f['field']) for c, v in classes.items() for f in v['fields'] if f.get('unresolved')]
print(len(classes), 'classes;', sum(len(v['fields']) for v in classes.values()), 'fields; unresolved:', len(unresolved))
for item in unresolved[:60]:
    print('  ', item)
