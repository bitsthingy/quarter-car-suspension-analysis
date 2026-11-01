function run_studies()
% Three comparisons, 60 parameter/input combinations, frequency responses.
root=fileparts(mfilename('fullpath')); out=fullfile(root,'results');
if ~isfolder(out), mkdir(out); end
diary(fullfile(out,'console_log.txt')); cleanup=onCleanup(@()diary('off')); %#ok<NASGU>
p=qc_parameters(); scenarios={'bump','sine','multisine'};
labels={'Soft','Baseline','Firm'}; ks=[12000 18000 30000]; cs=[1000 1500 2200];
comparison=table(); sweep=table();
for j=1:numel(scenarios)
    scenario=scenarios{j};
    f=figure('Color','w','Name',['Comparison: ' scenario]); tiledlayout(4,1);
    for k=1:3
        q=p; q.ks=ks(k); q.cs=cs(k); s=qc_simulate(q,scenario);
        comparison=[comparison;qc_metrics(s,q,scenario,labels{k})]; %#ok<AGROW>
        signals={s.r*1000,s.accel,s.travel*1000,s.dFz};
        yl={'Road [mm]','Body accel [m/s^2]','Travel [mm]','Dynamic tyre load [N]'};
        for ax=1:4
            nexttile(ax); hold on; plot(s.t,signals{ax},'LineWidth',1.1,...
                'DisplayName',labels{k}); grid on; ylabel(yl{ax});
        end
    end
    nexttile(2); legend('Location','best'); nexttile(4); xlabel('Time [s]');
    sgtitle(['Passive quarter-car: ' scenario]);
    exportgraphics(f,fullfile(out,['comparison_' scenario '.png']),'Resolution',160);
    if strcmp(scenario,'bump')
        sb=qc_simulate(p,scenario);
        trace=table(sb.t,sb.r,sb.x(:,1),sb.x(:,2),sb.x(:,3),sb.x(:,4),...
            sb.accel,sb.travel,sb.dFz,sb.Fz,'VariableNames',...
            {'Time_s','Road_m','Body_m','Body_velocity_mps','Wheel_m',...
            'Wheel_velocity_mps','Body_acceleration_mps2','Travel_m',...
            'Dynamic_tyre_load_N','Total_tyre_load_N'});
        writetable(trace,fullfile(out,'baseline_bump_trace.csv'));
    end
    fprintf('Parameter sweep: %s\n',scenario);
    for stiffness=[12000 18000 24000 30000]
        for damping=[600 1000 1500 2200 3000]
            q=p; q.ks=stiffness; q.cs=damping; s=qc_simulate(q,scenario);
            sweep=[sweep;qc_metrics(s,q,scenario,'Sweep')]; %#ok<AGROW>
        end
    end
end
% Pareto flags per input: minimise acceleration RMS, travel peak and load RMS.
sweep.Pareto_within_limits=false(height(sweep),1);
for j=1:numel(scenarios)
    ix=find(sweep.Scenario==string(scenarios{j}) & sweep.Within_assumed_limits);
    V=[sweep.Body_accel_RMS_mps2(ix),sweep.Travel_peak_mm(ix),...
        sweep.Tyre_dynamic_load_RMS_N(ix)];
    for k=1:numel(ix)
        dominated=any(all(V<=V(k,:),2)&any(V<V(k,:),2));
        sweep.Pareto_within_limits(ix(k))=~dominated;
    end
end
writetable(comparison,fullfile(out,'configuration_comparison.csv'));
writetable(sweep,fullfile(out,'parameter_sweep.csv'));
f=figure('Color','w','Name','Comfort and road-holding trade-off',...
    'Position',[50 50 1500 800]);
tiledlayout(1,3,'TileSpacing','loose','Padding','loose');
for j=1:numel(scenarios)
    nexttile; m=sweep.Scenario==string(scenarios{j});
    scatter(sweep.Body_accel_RMS_mps2(m),sweep.Dynamic_load_coefficient(m),...
        48,sweep.Travel_peak_mm(m),'filled'); hold on;
    front=m&sweep.Pareto_within_limits;
    plot(sweep.Body_accel_RMS_mps2(front),sweep.Dynamic_load_coefficient(front),...
        'ko','MarkerSize',11); grid on;
    cb=colorbar; cb.Label.String='Peak travel [mm]';
    xlabel('Body accel RMS [m/s^2]'); ylabel('Dynamic load / static load');
    title(scenarios{j});
end
sgtitle('Suspension trade-offs: black rings mark Pareto designs');
exportgraphics(f,fullfile(out,'tradeoffs.png'),'Resolution',300);
f=figure('Color','w','Name','Frequency response'); tiledlayout(3,1);
freq=logspace(log10(0.2),log10(20),500)';
frequencyTable=table(freq,'VariableNames',{'Frequency_Hz'});
for k=1:3
    q=p; q.ks=ks(k); q.cs=cs(k); [A,B]=qc_matrices(q); G=zeros(numel(freq),3);
    for j=1:numel(freq)
        w=2*pi*freq(j); H=(1i*w*eye(4)-A)\B;
        G(j,:)=[abs(A(2,:)*H),abs(H(1)-H(3)),abs(q.kt*(1-H(3)))];
    end
    yl={'Acceleration / road [(m/s^2)/m]','Travel / road [m/m]',...
        'Dynamic tyre load / road [N/m]'};
    for j=1:3
        nexttile(j); loglog(freq,G(:,j),'LineWidth',1.2,'DisplayName',labels{k});
        hold on; grid on; ylabel(yl{j});
    end
    frequencyTable.([labels{k} '_accel_per_m'])=G(:,1);
    frequencyTable.([labels{k} '_travel_per_m'])=G(:,2);
    frequencyTable.([labels{k} '_load_per_m'])=G(:,3);
end
nexttile(1); legend('Location','best'); nexttile(3); xlabel('Frequency [Hz]');
exportgraphics(f,fullfile(out,'frequency_response.png'),'Resolution',160);
writetable(frequencyTable,fullfile(out,'frequency_response.csv'));
save(fullfile(out,'study_workspace.mat'),'p','comparison','sweep');
disp(comparison); fprintf('Saved results to %s\n',out);
end
