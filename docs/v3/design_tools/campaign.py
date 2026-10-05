from kitchen_sim import *
import math
LOGF=[10.5,11.3,12.2,13.0,13.7,14.1,14.5,14.8, 15.1,15.25,15.4,15.6,15.7,15.8,15.9,16.0, 16.25,16.35,16.4,16.5,16.55,16.6,16.65,16.7]
MEFF=[1.0,1.1,1.25,1.5,1.8,2.2,2.6,3.0]+[3.0]*16
LIC=[0,0,0,1,2,4,8,12]+[24]*8+[36]*8
def nst(k): return 6 if k<2 else (7 if k<8 else 8)
def cap(k): return 100 if k<3 else (200 if k<8 else (300 if k<16 else 400))
cs=10/24; bs=10/24; rows=[]
for k in range(24):
    F=10**LOGF[k]
    dc,_=run(nst(k),cap(k),F,MEFF[k],'casual',start_day=cs,maxdays=25)
    db,_=run(nst(k),cap(k),F,MEFF[k],BINGE,start_day=bs,maxdays=25)
    rows.append((k+1,LOGF[k],round(cs,2),round(dc,2) if dc else None,round(bs,2),round(db,2) if db else None))
    print(rows[-1],flush=True)
    # licence for next city starts when this city opened
    nc = cs + (dc or 9); nb = bs + (db or 9)
    if k+1<24:
        nc=max(nc, cs+LIC[k+1]/24); nb=max(nb, bs+LIC[k+1]/24)
    cs, bs = nc, nb
print("casual end", round(cs,1), "binge end", round(bs,1))
