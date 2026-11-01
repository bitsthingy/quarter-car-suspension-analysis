function p = qc_parameters()
% Illustrative passenger-car values, not measured production-vehicle data.
p.ms=300; p.mu=40;       % Sprung and unsprung masses [kg]
p.ks=18000; p.kt=180000; % Suspension and tyre stiffnesses [N/m]
p.cs=1500;              % Suspension damping [N s/m]
p.g=9.81;
p.dt=0.002; p.T=8;      % Road/report interval and duration [s]
p.travelLimit=0.060;    % Assumed symmetric dynamic travel allowance [m]
end
