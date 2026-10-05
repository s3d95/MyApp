from kitchen_sim import *
import math, time
T=[0.2,0.8,1.2,1.6,2.0,2.5,3.0,3.0, 3.5,3.5,3.5,4.0,4.0,4.0,4.5,4.5, 5.0,5.0,5.0,5.5,5.5,6.0,6.0,6.0]
MEFF=[1.0,1.1,1.25,1.5,1.8,2.2,2.6,3.0]+[3.0]*16
def nst(k): return 6 if k<2 else (7 if k<8 else 8)
def cap(k): return 100 if k<3 else (200 if k<8 else (300 if k<16 else 400))
LIC=[0,0,0,1,2,4,8,12]+[24]*8+[36]*8  # hours, licence to OPEN city k (k index), starts when city k-1 opens
start=10/24; bstart=10/24; out=[]
for k in range(24):
    lo,hi=6.0,26.0
    for it in range(9):
        mid=(lo+hi)/2
        d,_=run(nst(k),cap(k),10**mid,MEFF[k],'casual',start_day=start,maxdays=20)
        if d is None or d>T[k]: hi=mid
        else: lo=mid
    F=10**lo
    dc,_=run(nst(k),cap(k),F,MEFF[k],'casual',start_day=start,maxdays=20)
    db,_=run(nst(k),cap(k),F,MEFF[k],BINGE,start_day=bstart,maxdays=20)
    out.append((k+1,nst(k),cap(k),MEFF[k],round(lo,2),round(start,2),dc,db,round(bstart,2)))
    print(out[-1],flush=True)
    start+= (dc or T[k])
    # binge: next city opens after max(own finish, licence of next)
    nb = bstart + (db or T[k]/3)
    if k+1<24: nb=max(nb, bstart + LIC[k+1]/24)
    bstart=nb
print("casual total",round(start,1),"binge total",round(bstart,1))
