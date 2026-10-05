"""Session-aware idle economy simulator (research prototype).

Models an AdCap-style generator economy, a greedy ROI bot (Frozen-Cookies style
score = cost/income + cost/dIncome), a daily session schedule with capped offline
earnings, and an optional sqrt prestige. Reports wall-clock days to milestones.
"""
import math, sys

# ---------------------------------------------------------------- economy configs
ADCAP = dict(
    name="AdCap Earth (reference)",
    # base cost, cost growth r, cycle seconds, revenue per cycle per unit
    st=[(4,1.07,0.6,1),(60,1.15,3,60),(720,1.14,6,540),(8640,1.13,12,4320),
        (103680,1.12,24,51840),(1244160,1.11,96,622080),(14929920,1.10,384,7464960),
        (179159040,1.09,1536,89579520),(2149908480,1.08,6144,1074954240),
        (25798901760,1.07,36864,29668737024)],
    speed_ms=[25,50,100,200,300,400], profit_ms_start=500, profit_ms_step=100, profit_ms_mult=4,
    all_ms=[25,50,100,200,300,400],
    # cash upgrades: (station or -1 for all, multiplier, price)
    cash=[(0,3,2.5e5),(1,3,5e5),(2,3,1e6),(3,3,5e6),(4,3,1e7),(5,3,2.5e7),(6,3,5e8),(7,3,1e10),
          (8,3,5e10),(9,3,2.5e11),(-1,3,1e12),(0,3,2e13),(1,3,5e13),(2,3,1e14),(3,3,5e14),
          (4,3,1e15),(5,3,2e15),(6,3,5e15),(7,3,7e15),(8,3,1e16),(9,3,2e16),(-1,3,5e16)],
    prestige=dict(k=150, div=1e15, power=0.5, per_unit=0.02),
)

def make_city(k, base_scale=1.0):
    """Proposed v3 city chapter k (0-based): 8 stations, steeper growth than AdCap
    early tiers so walls arrive, each city's goal scale grows with k."""
    rs=[1.09,1.15,1.14,1.13,1.12,1.11,1.10,1.09]
    times=[1,3,6,12,24,96,384,1536]
    st=[]
    c=5.0; rev=1.0
    for i in range(8):
        cost=5*12**i
        revenue=[1,60,540,4320,51840,622080,7464960,89579520][i]
        st.append((cost*base_scale, rs[i], times[i], revenue))
    return dict(name=f"City {k+1}", st=st, speed_ms=[10,25,50,100,150,200,250,300],
                profit_ms_start=10**9, profit_ms_step=100, profit_ms_mult=2,
                all_ms=[25,50,100,150,200,250,300],
                cash=[(i,3,5e5*20**i) for i in range(8)]+[(-1,3,1e12),(-1,3,1e15)],
                prestige=None)

# ---------------------------------------------------------------- state & income
class State:
    def __init__(s, cfg, meta_mult=1.0):
        s.cfg=cfg; n=len(cfg['st'])
        s.lv=[0]*n; s.lv[0]=1
        s.up=[False]*len(cfg['cash'])
        s.cash=0.0; s.life=0.0; s.meta=meta_mult
    def station_income(s,i,lv=None):
        cfg=s.cfg; c,r,t,rev=cfg['st'][i]
        n=s.lv[i] if lv is None else lv
        if n<=0: return 0.0
        sp=2**sum(1 for m in cfg['speed_ms'] if n>=m)
        pm=1.0
        if n>=cfg['profit_ms_start']:
            pm*=cfg['profit_ms_mult']**(1+(n-cfg['profit_ms_start'])//cfg['profit_ms_step'])
        for k,(j,m,p) in enumerate(cfg['cash']):
            if s.up[k] and (j==i or j==-1): pm*=m
        return n*rev*pm*sp/t
    def income(s, lv=None, up=None):
        cfg=s.cfg
        L=s.lv if lv is None else lv
        save_lv, save_up = s.lv, s.up
        s.lv=L; s.up=s.up if up is None else up
        mn=min(L)
        allsp=2**sum(1 for m in cfg['all_ms'] if mn>=m)
        tot=sum(s.station_income(i) for i in range(len(L)))*allsp*s.meta
        s.lv, s.up = save_lv, save_up
        return tot
    def lvl_cost(s,i,k):
        c,r,_,_=s.cfg['st'][i]; n=s.lv[i]
        # cost of next k levels; level 1 costs base, level n+1 costs base*r^n
        return c*r**n*(r**k-1)/(r-1)

def candidates(s):
    cfg=s.cfg; out=[]
    inc=s.income()
    for i in range(len(s.lv)):
        n=s.lv[i]
        nxt=[m for m in sorted(set(cfg['speed_ms']+cfg['all_ms'])) if m>n]
        ks={1}
        if nxt: ks.add(nxt[0]-n)
        if i>0 and s.lv[i-1]==0: continue  # must unlock in order
        for k in ks:
            cost=s.lvl_cost(i,k)
            lv=list(s.lv); lv[i]+=k
            d=s.income(lv=lv)-inc
            out.append((cost,d,('lv',i,k)))
    for k,(j,m,p) in enumerate(cfg['cash']):
        if not s.up[k]:
            up=list(s.up); up[k]=True
            d=s.income(up=up)-inc
            out.append((p,d,('up',k)))
    return out, inc

def apply(s,a):
    if a[0]=='lv': s.lv[a[1]]+=a[2]
    else: s.up[a[1]]=True

# ---------------------------------------------------------------- session model
def schedule(day_sessions):
    """day_sessions: list of (start_hour, minutes)."""
    return day_sessions

def run(cfg, targets, sessions=((8,12),(13,8),(21,15)), off_cap_h=4.0, off_eff=1.0,
        days=120, meta_mult=1.0, prestige_rule=None, log=False):
    s=State(cfg, meta_mult)
    angels=0.0; angels_life_base=0.0; resets=0
    hit={}; t=0.0  # t in hours of wall clock
    def check():
        for g in targets:
            if g not in hit and s.life+angels_life_base>=g: hit[g]=round(t/24,2)
    last_end=None
    for d in range(days):
        for (h,mins) in sessions:
            start=d*24+h
            if last_end is not None:
                gap=start-last_end
                earn=s.income()*3600*min(gap,off_cap_h)*off_eff
                s.cash+=earn; s.life+=earn
            t=start; end=start+mins/60
            check()
            # prestige decision at session start
            if cfg.get('prestige') and prestige_rule:
                P=cfg['prestige']
                tot=P['k']*(max(0,s.life+angels_life_base)/P['div'])**P['power']
                claim=tot-angels
                if (1+P['per_unit']*tot)/(1+P['per_unit']*angels)>=prestige_rule:
                    angels=tot; angels_life_base+=s.life; resets+=1
                    s=State(cfg, meta_mult*(1+P['per_unit']*angels))
            while t<end:
                cands,inc=candidates(s)
                if inc<=0: break
                best=None
                for cost,dI,a in cands:
                    if dI<=0: continue
                    score=max(0,cost-s.cash)/inc + cost/dI
                    if best is None or score<best[0]: best=(score,cost,a)
                if best is None: break
                _,cost,a=best
                if s.cash>=cost:
                    s.cash-=cost; apply(s,a); continue
                dt=(cost-s.cash)/inc/3600
                if t+dt<=end:
                    t+=dt; s.cash+=inc*dt*3600; s.life+=inc*dt*3600
                    s.cash-=cost; apply(s,a); check()
                else:
                    rem=end-t; s.cash+=inc*rem*3600; s.life+=inc*rem*3600; t=end; check()
            last_end=end
        if len(hit)==len(targets): break
    return hit, s, resets, angels

if __name__=="__main__":
    pass
