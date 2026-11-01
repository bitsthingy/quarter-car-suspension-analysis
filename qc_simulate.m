function s = qc_simulate(p,scenario,refine)
% Displacements start at static loaded equilibrium, so gravity cancels from A*x.
% Acceleration is calculated from force balance, not by differentiating samples.
% Base MATLAB only. Both implementations use the same sampled road.
if nargin<3, refine=1; end
t=(0:p.dt:p.T)'; r=qc_road(t,scenario);
road=griddedInterpolant(t,r,'linear','nearest'); [A,B]=qc_matrices(p);
opts=odeset('RelTol',1e-8/refine,'AbsTol',1e-10/refine,'MaxStep',p.dt/refine);
[~,x]=ode45(@(tt,xx)A*xx+B*road(tt),t,zeros(4,1),opts);
travel=x(:,1)-x(:,3);
accel=(-p.ks*travel-p.cs*(x(:,2)-x(:,4)))/p.ms;
dFz=p.kt*(r-x(:,3)); % Positive = increased normal force on wheel
s=struct('t',t,'r',r,'x',x,'accel',accel,'travel',travel,...
    'dFz',dFz,'Fz',(p.ms+p.mu)*p.g+dFz);
end
