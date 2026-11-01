"""Independent checks executed in Python/SciPy, not MATLAB or Simulink.
Exact first-order-hold integration is compared with direct Newton force balance
using solve_ivp and with RK4 at the Simulink builder's configured time step.
Optional dependencies for reproducing: numpy scipy matplotlib.
"""
from pathlib import Path
import csv
import numpy as np
from scipy.linalg import expm
from scipy.integrate import solve_ivp, cumulative_trapezoid
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

ROOT=Path(__file__).resolve().parent
OUT=ROOT/"reference_results"
OUT.mkdir(exist_ok=True)
MS,MU,KT,G=300.,40.,180000.,9.81
DT,T=0.002,8.
t=np.arange(round(T/DT)+1)*DT
checks=[]

def road(t,scenario):
    tau=t-1
    gate=np.where(tau<=0,0,np.where(tau<0.5,0.5*(1-np.cos(np.pi*tau/0.5)),1))
    if scenario=="bump":
        return np.where((tau>=0)&(tau<=0.3),0.025*(1-np.cos(2*np.pi*tau/0.3)),0)
    if scenario=="sine":
        return gate*0.01*np.sin(2*np.pi*1.2*tau)
    f=[0.6,1.1,1.8,3.2,5.5,8,11.5,15]
    a=np.array([3,2.5,2,1.5,1,0.8,0.5,0.3])*1e-3
    phase=[0,0.7,1.8,2.1,0.4,2.8,1.2,2.5]
    return gate*sum(aa*np.sin(2*np.pi*ff*tau+pp) for aa,ff,pp in zip(a,f,phase))

def matrix(ks,cs):
    A=np.array([[0,1,0,0],[-ks/MS,-cs/MS,ks/MS,cs/MS],
        [0,0,0,1],[ks/MU,cs/MU,-(ks+KT)/MU,-cs/MU]])
    B=np.array([0,0,0,KT/MU])
    return A,B

def exact(scenario,ks=18000.,cs=1500.):
    r=road(t,scenario); A,B=matrix(ks,cs)
    # Augment the state with road height and its constant slope per interval.
    augmented=np.zeros((6,6)); augmented[:4,:4]=A
    augmented[:4,4]=B; augmented[4,5]=1
    F=expm(augmented*DT)
    x=np.zeros((len(t),4))
    for i in range(len(t)-1):
        initial=np.r_[x[i],r[i],(r[i+1]-r[i])/DT]
        x[i+1]=(F@initial)[:4]
    return r,x

def signals(x,r,ks,cs):
    travel=x[:,0]-x[:,2]
    acc=(-ks*travel-cs*(x[:,1]-x[:,3]))/MS
    load=KT*(r-x[:,2])
    return np.column_stack((x,acc,travel,load))

def force_rhs(tt,x,r,ks,cs):
    zr=np.interp(tt,t,r)
    Fs=ks*(x[0]-x[2])+cs*(x[1]-x[3])
    Ft=KT*(zr-x[2])
    return np.array([x[1],-Fs/MS,x[3],(Fs+Ft)/MU])

def record(name,value,limit):
    checks.append(dict(Check=name,Value=float(value),Maximum_allowed=limit,
                       Pass=bool(value<=limit)))

def metrics(scenario,label,ks,cs):
    r,x=exact(scenario,ks,cs); Y=signals(x,r,ks,cs)
    first=1 if scenario=="bump" else 2
    mask=t>=first
    def rms(v): return np.sqrt(np.trapezoid(v[mask]**2,t[mask])/(T-first))
    min_load=np.min((MS+MU)*G+Y[:,6]); peak_travel=np.max(np.abs(Y[:,5]))
    return dict(Configuration=label,Scenario=scenario,ks_Npm=ks,cs_Nspm=cs,
        RMS_window_start_s=first,Body_accel_RMS_mps2=rms(Y[:,4]),
        Body_accel_peak_mps2=np.max(np.abs(Y[:,4])),Travel_peak_mm=1000*peak_travel,
        Tyre_dynamic_load_RMS_N=rms(Y[:,6]),
        Dynamic_load_coefficient=rms(Y[:,6])/((MS+MU)*G),
        Minimum_total_tyre_load_N=min_load,
        Within_assumed_limits=bool(peak_travel<=0.06 and min_load>0))

A,B=matrix(18000,1500)
record("Constant_road_equilibrium",np.linalg.norm(A@np.array([.01,0,.01,0])+B*.01),1e-10)
record("Largest_pole_real_part",max(np.linalg.eigvals(A).real),0)
for scenario in ["bump","sine","multisine"]:
    r,x=exact(scenario)
    sol=solve_ivp(lambda tt,xx:force_rhs(tt,xx,r,18000,1500),(0,T),np.zeros(4),
                  t_eval=t,rtol=1e-10,atol=1e-12,max_step=DT/2)
    assert sol.success
    ref=signals(x,r,18000,1500)
    test=signals(sol.y.T,r,18000,1500)
    err=np.linalg.norm(ref-test,axis=0)/np.linalg.norm(ref,axis=0)
    record(scenario+"_force_ODE_vs_exact_max_relative",max(err),1e-5)
    # Direct RK4 on Newton forces, at 1 ms, as configured in build_simulink.
    h=0.001; xr=np.zeros((round(T/h)+1,4))
    for i in range(len(xr)-1):
        tt=i*h; xx=xr[i]
        k1=force_rhs(tt,xx,r,18000,1500)
        k2=force_rhs(tt+h/2,xx+h*k1/2,r,18000,1500)
        k3=force_rhs(tt+h/2,xx+h*k2/2,r,18000,1500)
        k4=force_rhs(tt+h,xx+h*k3,r,18000,1500)
        xr[i+1]=xx+h*(k1+2*k2+2*k3+k4)/6
    test=signals(xr[::2],r,18000,1500)
    err=np.linalg.norm(ref-test,axis=0)/np.linalg.norm(ref,axis=0)
    record(scenario+"_RK4_1ms_vs_exact_max_relative",max(err),1e-3)

for cs in [1500.,0.]:
    A,_=matrix(18000,cs); tt=np.arange(2001)*.002
    x=solve_ivp(lambda _,xx:A@xx,(0,4),[.01,0,0,0],
                  t_eval=tt,rtol=1e-11,atol=1e-13,max_step=.002).y.T
    E=.5*MS*x[:,1]**2+.5*MU*x[:,3]**2+.5*18000*(x[:,0]-x[:,2])**2+.5*KT*x[:,2]**2
    if cs:
        diss=cumulative_trapezoid(cs*(x[:,1]-x[:,3])**2,tt,initial=0)
        record("Free_decay_energy_balance_relative",max(abs(E-E[0]+diss))/E[0],2e-3)
        record("Free_decay_energy_increase_J",max(np.diff(E)),1e-8)
    else:
        record("Undamped_energy_conservation_relative",max(abs(E-E[0]))/E[0],1e-6)

def write_csv(name,rows):
    with (OUT/name).open("w",newline="") as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0])); w.writeheader(); w.writerows(rows)

configs=[("Soft",12000,1000),("Baseline",18000,1500),("Firm",30000,2200)]
comparison=[metrics(sc,label,ks,cs) for sc in ["bump","sine","multisine"] for label,ks,cs in configs]
sweep=[metrics(sc,"Sweep",ks,cs) for sc in ["bump","sine","multisine"]
       for ks in [12000,18000,24000,30000] for cs in [600,1000,1500,2200,3000]]
write_csv("python_reference_comparison.csv",comparison)
write_csv("python_reference_sweep.csv",sweep)
write_csv("python_verification.csv",checks)
r,x=exact("bump")
fig,axs=plt.subplots(4,1,figsize=(9,10),sharex=True,layout="constrained")
axs[0].plot(t,r*1000,color="black",label="Road")
for label,ks,cs in configs:
    r,x=exact("bump",ks,cs); Y=signals(x,r,ks,cs)
    axs[0].plot(t,x[:,0]*1000,label=label+" body")
    axs[1].plot(t,Y[:,4],label=label)
    axs[2].plot(t,Y[:,5]*1000,label=label)
    axs[3].plot(t,Y[:,6],label=label)
for ax,yl in zip(axs,["Displacement [mm]","Body acceleration [m/s²]",
                      "Suspension travel [mm]","Dynamic tyre load [N]"]):
    ax.set_ylabel(yl); ax.grid(alpha=.25)
axs[0].legend(ncol=2); axs[-1].set_xlabel("Time [s]")
fig.suptitle("Independent Python reference: 50 mm bump (not a MATLAB run)")
fig.savefig(OUT/"python_reference_bump.png",dpi=150)
plt.close(fig)
text=["EXECUTION STATUS: independent Python/SciPy reference calculation.",
      "Actual MATLAB/Simulink verification is recorded separately in results/.",
      "",
      f"Independent checks passed: {sum(c['Pass'] for c in checks)}/{len(checks)}",
      "Methods: exact sampled-road integration, direct force ODE, fixed-step RK4.",
      "These checks do not prove the .m files or Simulink builder execute.",
      "Run verify_project and verify_simulink to reproduce the MATLAB checks.",
      "",
      "Baseline bump metrics (independent Python reference):"]
text += [f"{k}: {v}" for k,v in comparison[1].items()]
(OUT/"EXECUTION_STATUS.txt").write_text("\n".join(text),encoding="utf-8")
print("\n".join(text))
for c in checks: print(c)
assert all(c["Pass"] for c in checks),"Independent verification failed"
