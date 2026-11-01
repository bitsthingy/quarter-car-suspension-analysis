% ENTRY POINT: run this first.
clear; clc; close all;
projectFolder=fileparts(mfilename('fullpath')); cd(projectFolder); addpath(projectFolder);
fprintf('Quarter-car project | MATLAB %s\n',version);
p=qc_parameters();
fprintf('ms=%.0f kg, mu=%.0f kg, ks=%.0f N/m, cs=%.0f N s/m\n',p.ms,p.mu,p.ks,p.cs);
s=qc_simulate(p,'bump');
figure('Name','First quarter-car run','Color','w'); tiledlayout(3,1);
nexttile; plot(s.t,1000*[s.r s.x(:,1) s.x(:,3)],'LineWidth',1.2);
ylabel('Displacement [mm]'); legend('Road','Body','Wheel'); grid on;
title('50 mm smooth bump: baseline passive suspension');
nexttile; plot(s.t,s.accel,'LineWidth',1.2);
ylabel('Body acceleration [m/s^2]'); grid on;
nexttile; plot(s.t,1000*s.travel,'LineWidth',1.2);
ylabel('Suspension travel [mm]'); xlabel('Time [s]'); grid on;
disp(qc_metrics(s,p,'bump','Baseline'));
fprintf('\nNext: verify_project, run_studies, build_simulink, verify_simulink.\n');
