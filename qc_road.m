function r = qc_road(t,scenario)
% Time-domain demonstrations, NOT an ISO road classification.
t=t(:); tau=t-1; r=zeros(size(t));
switch char(scenario)
    case 'bump'
        use=tau>=0 & tau<=0.30;
        r(use)=0.025*(1-cos(2*pi*tau(use)/0.30)); % 50 mm peak
    case {'sine','multisine'}
        gate=zeros(size(t)); ramp=tau>0 & tau<0.5;
        gate(ramp)=0.5*(1-cos(pi*tau(ramp)/0.5)); gate(tau>=0.5)=1;
        if strcmp(scenario,'sine')
            r=gate.*(0.01*sin(2*pi*1.2*tau));
        else
            f=[0.6 1.1 1.8 3.2 5.5 8 11.5 15];
            a=[3 2.5 2 1.5 1 0.8 0.5 0.3]*1e-3;
            phase=[0 0.7 1.8 2.1 0.4 2.8 1.2 2.5];
            for k=1:numel(f)
                r=r+a(k)*sin(2*pi*f(k)*tau+phase(k));
            end
            r=gate.*r;
        end
    otherwise
        error('Unknown road scenario: %s',scenario);
end
end
