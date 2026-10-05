import re,sys
keys=set(open('/home/user/MyApp/tools/art_keys.txt').read().split())
bad={}
for fn in sys.argv[1:]:
    txt=open(fn,encoding='utf-8').read()
    for m in re.finditer(r'\b((?:food|ppl|face|bld|veh|ui|ani)_[a-z0-9_]+)\b',txt):
        k=m.group(1)
        if k not in keys:
            bad.setdefault(k,[]).append(fn+':'+str(txt[:m.start()].count('\n')+1))
used=set(re.findall(r'\b((?:food|ppl|face|bld|veh|ui|ani)_[a-z0-9_]+)\b',''.join(open(f,encoding='utf-8').read() for f in sys.argv[1:])))
print("distinct art keys referenced:",len(used&keys))
for k,v in sorted(bad.items()): print("BAD",k,v[:5])
print("bad count",len(bad))
