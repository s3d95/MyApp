"""Calibration sim for the v3 Kitchen engine (GDD section 2/3).
Base units (priceScale=1). Greedy ROI bot. Session profiles. Offline cap/eff by day.
Used only to place each city's final cash goal (finalGoalBase) and check binge ratio."""
import math, sys

CYCLE=[1,3,6,12,24,96,384,1536]
REV  =[1,60,540,4320,51840,622080,7464960,89579520]
R    =[1.09,1.15,1.14,1.13,1.12,1.11,1.10,1.09]
MGR  =[200,200,120,60,15,8,6,4]
ST_MS=[10,25,50,100,150,200,250,300,350,400]
ALL_MS=[25,50,100,150,200,250,300,400]
def base_cost(i): return 5*12**i
UP0=2.5e5; UPG=20.0
UNMANAGED=0.4
HUMAN_S=2.0

class City:
    def __init__(s, n, cap, final, meff):
        s.n=n; s.cap=cap; s.final=final; s.meff=meff
        s.lv=[0]*n; s.lv[0]=1; s.mgr=[False]*n
        order=list(range(n))+[-1]+list(range(n))+[-1]
        nu=len(order)
        s.ups=[(t, UP0*UPG**j) for j,t in enumerate(order)]
        s.got=[False]*nu
        s.cash=0.0; s.life=0.0
    def st_inc(s,i,lv=None,got=None):
        n=s.lv[i] if lv is None else lv[i]
        if n<=0: return 0.0
        k=sum(1 for m in ST_MS if n>=m)
        mult=2**k
        g=s.got if got is None else got
        for j,(t,p) in enumerate(s.ups):
            if g[j] and (t==i or t==-1): mult*=3
        return n*REV[i]*mult/CYCLE[i]
    def income(s, lv=None, got=None, managed_only=False):
        L=s.lv if lv is None else lv
        mn=min(L)
        a=2**sum(1 for m in ALL_MS if mn>=m)
        tot=0.0
        for i in range(s.n):
            if managed_only and not s.mgr[i]: continue
            tot+=s.st_inc(i,L,got)*(1.0 if s.mgr[i] else UNMANAGED)
        return tot*a*s.meff
    def cost(s,i,k):
        n=s.lv[i]; b=base_cost(i); r=R[i]
        return b*r**n*(r**k-1)/(r-1)

def candidates(c):
    out=[]; inc=c.income()
    for i in range(c.n):
        n=c.lv[i]
        if i>0 and c.lv[i-1]==0: continue
        if n>=c.cap: continue
        ks={1}
        nxt=[m for m in sorted(set(ST_MS+ALL_MS)) if m>n and m<=c.cap]
        if nxt: ks.add(nxt[0]-n)
        for k in ks:
            k=min(k,c.cap-n)
            lv=list(c.lv); lv[i]+=k
            out.append((c.cost(i,k), c.income(lv=lv)-inc, ('lv',i,k)))
    for j,(t,p) in enumerate(c.ups):
        if not c.got[j]:
            g=list(c.got); g[j]=True
            out.append((p, c.income(got=g)-inc, ('up',j)))
    for i in range(c.n):
        if c.lv[i]>0 and not c.mgr[i]:
            out.append((base_cost(i)*MGR[i], None, ('mgr',i)))
    return out, inc

def apply(c,a):
    if a[0]=='lv': c.lv[a[1]]+=a[2]
    elif a[0]=='up': c.got[a[1]]=True
    else: c.mgr[a[1]]=True

def offline_params(day):
    cap=min(12.0, 3.0+day/6.0)
    eff=min(1.0, 0.5+day/120.0)
    return cap,eff

CASUAL=[(8,12),(13,8),(21,15)]
CASUAL0=[(10,25),(14,8),(21,12)]
BINGE=[(9,120),(12,120),(16,120),(20,120)]

def run(n,cap,final,meff,profile,start_day=0.0,A=1.5,maxdays=60):
    c=City(n,cap,final,meff)
    t=None; last=None
    d=int(start_day)
    while d<start_day+maxdays:
        ses = profile if profile!='casual' else (CASUAL0 if d==0 else CASUAL)
        if profile=='casual': ses = CASUAL0 if d==0 else CASUAL
        for h,mins in ses:
            st=d*24+h
            if st < start_day*24: continue
            if last is not None:
                gap=st-last; oc,oe=offline_params(st/24)
                e=c.income(managed_only=True)*3600*min(gap,oc)*oe
                c.cash+=e; c.life+=e
                if c.life>=final: return (st - start_day*24)/24, c
            t=st; end=st+mins/60.0
            while t<end:
                cands,inc=candidates(c)
                inc*=A
                best=None
                for cost,dI,a in cands:
                    if a[0]=='mgr':
                        # value manager highly when station unmanaged
                        score=max(0,cost-c.cash)/max(inc,1e-9)
                        if cost > 180*max(inc,1e-9): continue
                    else:
                        if dI is None or dI<=0: continue
                        score=max(0,cost-c.cash)/max(inc,1e-9)+cost/(dI*A)
                    if best is None or score<best[0]: best=(score,cost,a)
                if best is None:
                    rem=end-t; c.cash+=inc*rem*3600; c.life+=inc*rem*3600; t=end; break
                _,cost,a=best
                if c.cash>=cost:
                    c.cash-=cost; apply(c,a); t+=HUMAN_S/3600; c.cash+=inc*HUMAN_S; c.life+=inc*HUMAN_S; continue
                dt=(cost-c.cash)/max(inc,1e-9)/3600
                if t+dt<=end:
                    t+=dt; c.cash+=inc*dt*3600; c.life+=inc*dt*3600; c.cash-=cost; apply(c,a)
                else:
                    rem=end-t; c.cash+=inc*rem*3600; c.life+=inc*rem*3600; t=end
                if c.life>=final: return (t - start_day*24)/24, c
            last=end
        d+=1
    return None, c

if __name__=="__main__":
    import itertools
    n=int(sys.argv[1]); cap=int(sys.argv[2]); meff=float(sys.argv[3]); sd=float(sys.argv[4])
    for e in range(6,22):
        F=10.0**e
        dc,c=run(n,cap,F,meff,'casual',start_day=sd)
        db,_=run(n,cap,F,meff,BINGE,start_day=sd)
        print(f"F=1e{e}: casual {dc if dc is None else round(dc,2)} d  binge {db if db is None else round(db,2)} d  lv={c.lv}")
