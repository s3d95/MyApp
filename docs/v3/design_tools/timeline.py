from kitchen_sim import *
import sys
n=int(sys.argv[1]); cap=int(sys.argv[2]); meff=float(sys.argv[3]); A=float(sys.argv[4]) if len(sys.argv)>4 else 1.5
c=City(n,cap,1e30,meff)
t=0.0; marks=[0.5,1,2,3,5,8,10,15,20,25]; mi=0
events=[]
while t<25*60:
    cands,inc=candidates(c); inc*=A
    best=None
    for cost,dI,a in cands:
        if a[0]=='mgr':
            score=max(0,cost-c.cash)/max(inc,1e-9)
            if cost > 180*max(inc,1e-9): continue
        else:
            if dI is None or dI<=0: continue
            score=max(0,cost-c.cash)/max(inc,1e-9)+cost/(dI*A)
        if best is None or score<best[0]: best=(score,cost,a)
    _,cost,a=best
    dt=max(0,(cost-c.cash)/max(inc,1e-9))
    while mi<len(marks) and t+dt>=marks[mi]*60:
        tt=marks[mi]*60; life=c.life+inc*(tt-t)
        print(f"t={marks[mi]}min life={life:.3g} inc/s={inc:.3g} lv={c.lv} mgr={sum(c.mgr)} ups={sum(c.got)}"); mi+=1
    dt+=HUMAN_S
    t+=dt; c.cash+=inc*dt; c.life+=inc*dt; c.cash-=cost; apply(c,a)
    if a[0]!='lv' or (a[0]=='lv' and c.lv[a[1]]==a[2]):
        events.append((round(t/60,2),a))
for e in events[:40]: print(e)
