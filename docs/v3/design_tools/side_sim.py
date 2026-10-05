import kitchen_sim as K
# side kitchen tier table (contracts & weekend venue)
K.CYCLE=[2,8,30,120,480]
K.REV=[2,60,1500,40000,1.2e6]
K.R=[1.10,1.12,1.13,1.14,1.15]
K.MGR=[20,20,15,10,8]
K.ST_MS=[10,25,50,75,100,125,150]
K.ALL_MS=[25,50,100,150]
K.base_cost=lambda i:[10,150,2500,40000,8e5][i]
K.UP0=2e4; K.UPG=30.0
import sys
def life_at(n,hours,profile):
    # run with impossible final, return lifetime at end of window
    c=None
    d,c=K.run(n,150,1e40,1.0,profile,start_day=10/24,maxdays=hours/24+0.01)
    return c.life
for n in (3,4,5):
  for h in (48,72,96,120):
    lc=life_at(n,h,'casual'); lb=life_at(n,h,K.BINGE)
    print(n,h,f"casual {lc:.3g} binge {lb:.3g}")
