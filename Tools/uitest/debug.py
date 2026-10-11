import sys, os, shutil
root='/Users/miro/Documents/GitHub/FViewer/FViewer/'
cap="        if DebugSnapshot.wantCapture { DebugSnapshot.wantCapture = false; let texture = drawable.texture; buffer.addCompletedHandler { _ in DispatchQueue.main.async { DebugSnapshot.save(texture) } } }\n"
targets=[('Viewport/ViewportRenderer.swift',"        buffer.present(drawable)\n"),('Viewport/Effect2DViewport.swift',"        buffer.present(drawable)\n")]
hook=('Model/AppModel.swift',"            open(URL(fileURLWithPath: arguments[flag + 1]))\n        }\n","        DebugSnapshot.schedule(self)\n")
if sys.argv[1]=='on':
    shutil.copy(sys.argv[2], root+'DebugSnapshot.swift')
    for path,anchor in targets:
        s=open(root+path).read()
        if 'DebugSnapshot' not in s:
            assert anchor in s; s=s.replace(anchor,cap+anchor,1); open(root+path,'w').write(s)
    s=open(root+hook[0]).read()
    if 'DebugSnapshot' not in s:
        assert hook[1] in s; s=s.replace(hook[1],hook[1]+hook[2],1); open(root+hook[0],'w').write(s)
else:
    if os.path.exists(root+'DebugSnapshot.swift'): os.remove(root+'DebugSnapshot.swift')
    for path in [t[0] for t in targets]+[hook[0]]:
        s=open(root+path).read()
        open(root+path,'w').write('\n'.join(l for l in s.split('\n') if 'DebugSnapshot' not in l))
