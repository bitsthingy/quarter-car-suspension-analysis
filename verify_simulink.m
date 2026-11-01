function checks = verify_simulink()
% Compare independently connected force-balance blocks with MATLAB equations.
root=fileparts(mfilename('fullpath')); model='quarter_car_passive';
if ~isfile(fullfile(root,[model '.slx'])), build_simulink(); end
load_system(fullfile(root,[model '.slx']));
out=fullfile(root,'results'); if ~isfolder(out), mkdir(out); end
p=qc_parameters(); ws=get_param(model,'ModelWorkspace'); assignin(ws,'p',p);
scenarios={'bump','sine','multisine'}; checks=table();
names=["Body_displacement";"Body_velocity";"Wheel_displacement";...
    "Wheel_velocity";"Body_acceleration";"Suspension_travel";"Dynamic_tyre_load"];
for k=1:numel(scenarios)
    s=qc_simulate(p,scenarios{k}); assignin(ws,'qc_road_input',[s.t s.r]);
    simout=sim(model); y=simout.get('qc_logged');
    yy=interp1(y.Time,squeeze(y.Data),s.t,'linear');
    ref=[s.x s.accel s.travel s.dFz];
    relative=vecnorm(yy-ref)./max(vecnorm(ref),eps);
    rows=table(repmat(string(scenarios{k}),7,1),names,relative',...
        relative'<1e-3,'VariableNames',{'Scenario','Signal','Relative_L2_error','Pass'});
    checks=[checks;rows]; %#ok<AGROW>
end
% Restore baseline bump before saving the model.
t=(0:p.dt:p.T)'; assignin(ws,'qc_road_input',[t qc_road(t,'bump')]);
save_system(model); writetable(checks,fullfile(out,'simulink_verification.csv'));
disp(checks); assert(all(checks.Pass),'MATLAB/Simulink agreement check failed.');
fprintf('All 21 MATLAB/Simulink signal comparisons passed.\n');
end
