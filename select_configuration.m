function [choice,selectedRuns] = select_configuration()
% Reproduce the documented choice from the existing 60-case sweep.
% This ranks a finite grid under explicit constraints, not a global optimum.
root=fileparts(mfilename('fullpath')); outdir=fullfile(root,'results');
inputFile=fullfile(outdir,'parameter_sweep.csv');
assert(isfile(inputFile),'Run run_studies before selecting a configuration.');
sweep=readtable(inputFile);
road=string(sweep.Scenario)=="multisine";
base=sweep(road & sweep.ks_Npm==18000 & sweep.cs_Nspm==1500,:);
assert(height(base)==1,'Expected exactly one multisine baseline row.');
criteria=struct('SelectionRoad','multisine',...
    'Objective','Minimise body acceleration RMS',...
    'MaximumTravel_mm',base.Travel_peak_mm,...
    'MaximumTyreLoadRMS_N',1.05*base.Tyre_dynamic_load_RMS_N);
eligible=road & sweep.Within_assumed_limits==1 & ...
    sweep.Travel_peak_mm<=criteria.MaximumTravel_mm & ...
    sweep.Tyre_dynamic_load_RMS_N<=criteria.MaximumTyreLoadRMS_N;
candidates=sortrows(sweep(eligible,:),'Body_accel_RMS_mps2');
assert(~isempty(candidates),'No tested configuration meets the selection rule.');
choice=candidates(1,:);
selectedRuns=sweep(sweep.ks_Npm==choice.ks_Npm & ...
    sweep.cs_Nspm==choice.cs_Nspm,:);
writetable(choice,fullfile(outdir,'selected_configuration.csv'));
writetable(selectedRuns,fullfile(outdir,'selected_configuration_all_roads.csv'));
save(fullfile(outdir,'selection_record.mat'),'choice','base','criteria','selectedRuns');
disp(selectedRuns);
fprintf('Selected ks=%g N/m, cs=%g N s/m under the documented rule.\n',...
    choice.ks_Npm,choice.cs_Nspm);
end
