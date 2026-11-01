function checks = verify_project()
% Equation/numerical verification, NOT experimental validation.
p=qc_parameters(); [A,B]=qc_matrices(p);
names=strings(0,1); values=[]; limits=[];
record('Zero_input_equilibrium',norm(A*zeros(4,1)),1e-12);
r=0.01; xe=[r;0;r;0]; record('Constant_road_equilibrium',norm(A*xe+B*r),1e-10);
record('Largest_pole_real_part',max(real(eig(A))),0);
opts=odeset('RelTol',1e-10,'AbsTol',1e-12,'MaxStep',p.dt);
[t,x]=ode45(@(~,xx)A*xx,(0:p.dt:4)',[0.01;0;0;0],opts);
vrel=x(:,2)-x(:,4);
E=0.5*p.ms*x(:,2).^2+0.5*p.mu*x(:,4).^2+...
    0.5*p.ks*(x(:,1)-x(:,3)).^2+0.5*p.kt*x(:,3).^2;
balance=E-E(1)+cumtrapz(t,p.cs*vrel.^2);
record('Energy_balance_relative_error',max(abs(balance))/E(1),2e-3);
record('Maximum_free_energy_increase_J',max(diff(E)),1e-8);
s=qc_simulate(p,'bump'); fine=qc_simulate(p,'bump',2);
record('Bump_acceleration_convergence_relative',...
    norm(s.accel-fine.accel)/max(norm(fine.accel),eps),1e-4);
q=p; q.cs=0; [Au,~]=qc_matrices(q);
[~,xu]=ode45(@(~,xx)Au*xx,(0:p.dt:2)',[0.01;0;0;0],opts);
Eu=0.5*q.ms*xu(:,2).^2+0.5*q.mu*xu(:,4).^2+...
    0.5*q.ks*(xu(:,1)-xu(:,3)).^2+0.5*q.kt*xu(:,3).^2;
record('Undamped_energy_conservation_relative',max(abs(Eu-Eu(1)))/Eu(1),1e-6);
checks=table(names,values,limits,values<=limits,...
    'VariableNames',{'Check','Value','Maximum_allowed','Pass'});
out=fullfile(fileparts(mfilename('fullpath')),'results');
if ~isfolder(out), mkdir(out); end
writetable(checks,fullfile(out,'verification.csv')); disp(checks);
assert(all(checks.Pass),'Verification failed; inspect results/verification.csv.');
fprintf('All equation and numerical checks passed.\n');
    function record(name,value,limit)
        names(end+1,1)=string(name); values(end+1,1)=value; limits(end+1,1)=limit;
    end
end
