function build_simulink()
% Spring and damper forces act oppositely on body and wheel.
% Each mass uses two integrators: acceleration -> velocity -> displacement.
% Force-balance model using standard Simulink blocks; no Simscape required.
assert(license('test','Simulink'),'Simulink licence is required for this stage.');
root=fileparts(mfilename('fullpath')); model='quarter_car_passive';
if bdIsLoaded(model)
    open_system(model); fprintf('Existing open model preserved.\n'); return;
end
if isfile(fullfile(root,[model '.slx']))
    open_system(fullfile(root,[model '.slx']));
    fprintf('Existing saved model preserved.\n'); return;
end
load_system('simulink'); new_system(model);
p=qc_parameters(); t=(0:p.dt:p.T)'; r=qc_road(t,'bump');
ws=get_param(model,'ModelWorkspace'); assignin(ws,'p',p);
assignin(ws,'qc_road_input',[t r]);
set_param(model,'SolverType','Fixed-step','Solver','ode4','FixedStep','0.001',...
    'StopTime',num2str(p.T),'ReturnWorkspaceOutputs','on');
add('simulink/Sources/From Workspace','Road',[30 410 150 440],...
    'VariableName','qc_road_input','Interpolate','on');
add('simulink/Math Operations/Sum','Tyre_deflection',[205 400 230 450],'Inputs','+-');
add('simulink/Math Operations/Gain','Tyre_stiffness',[275 400 350 450],'Gain','p.kt');
add('simulink/Math Operations/Sum','Suspension_travel',[45 70 70 120],'Inputs','+-');
add('simulink/Math Operations/Gain','Spring',[120 70 195 120],'Gain','p.ks');
add('simulink/Math Operations/Sum','Relative_velocity',[45 220 70 270],'Inputs','+-');
add('simulink/Math Operations/Gain','Damper',[120 220 195 270],'Gain','p.cs');
add('simulink/Math Operations/Sum','Body_force',[270 100 295 150],'Inputs','--');
add('simulink/Math Operations/Gain','Body_inverse_mass',[345 100 420 150],'Gain','1/p.ms');
add('simulink/Continuous/Integrator','Body_velocity',[470 105 505 140]);
add('simulink/Continuous/Integrator','Body_displacement',[555 105 590 140]);
add('simulink/Math Operations/Sum','Wheel_force',[395 280 420 340],'Inputs','+++');
add('simulink/Math Operations/Gain','Wheel_inverse_mass',[470 285 545 335],'Gain','1/p.mu');
add('simulink/Continuous/Integrator','Wheel_velocity',[590 290 625 325]);
add('simulink/Continuous/Integrator','Wheel_displacement',[680 290 715 325]);
add('simulink/Signal Routing/Mux','Outputs',[825 65 830 365],'Inputs','7');
add('simulink/Sinks/To Workspace','Logged_outputs',[905 140 1020 180],...
    'VariableName','qc_logged','SaveFormat','Timeseries');
add('simulink/Sinks/Scope','Response_scope',[925 270 980 310]);
wire('Road/1','Tyre_deflection/1'); wire('Wheel_displacement/1','Tyre_deflection/2');
wire('Tyre_deflection/1','Tyre_stiffness/1');
wire('Body_displacement/1','Suspension_travel/1');
wire('Wheel_displacement/1','Suspension_travel/2'); wire('Suspension_travel/1','Spring/1');
wire('Body_velocity/1','Relative_velocity/1'); wire('Wheel_velocity/1','Relative_velocity/2');
wire('Relative_velocity/1','Damper/1');
wire('Spring/1','Body_force/1'); wire('Damper/1','Body_force/2');
wire('Body_force/1','Body_inverse_mass/1'); wire('Body_inverse_mass/1','Body_velocity/1');
wire('Body_velocity/1','Body_displacement/1');
wire('Spring/1','Wheel_force/1'); wire('Damper/1','Wheel_force/2');
wire('Tyre_stiffness/1','Wheel_force/3'); wire('Wheel_force/1','Wheel_inverse_mass/1');
wire('Wheel_inverse_mass/1','Wheel_velocity/1'); wire('Wheel_velocity/1','Wheel_displacement/1');
signals={'Body_displacement','Body_velocity','Wheel_displacement','Wheel_velocity',...
    'Body_inverse_mass','Suspension_travel','Tyre_stiffness'};
for k=1:numel(signals), wire([signals{k} '/1'],['Outputs/' num2str(k)]); end
wire('Outputs/1','Logged_outputs/1'); wire('Outputs/1','Response_scope/1');
Simulink.BlockDiagram.arrangeSystem(model);
save_system(model,fullfile(root,[model '.slx']));
open_system(model); fprintf('Built %s.slx. Next: verify_simulink.\n',model);
    function add(source,name,position,varargin)
        add_block(source,[model '/' name],'Position',position,varargin{:});
    end
    function wire(source,dest)
        add_line(model,source,dest,'autorouting','on');
    end
end
