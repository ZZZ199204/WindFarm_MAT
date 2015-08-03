classdef pol_sim
%For each run, stores essential things and has an update method

    properties
        state; %newest to oldest
        battery; 
        profit;
        rt_sd_ct_bat;
        C;
        ramping;
        D; %Period
        L; % Number of observations
        eta_p; %efficiency while charging
        eta_n; %efficiency while discharging
    end
    
    methods
        function obj = pol_sim(D,L,Cin,state_initial,batinitial,ramping,etas)
        % constructor
            if ~exist('state_initial','var')
                state_initial=zeros(D,1);
            end
            if ~exist('batinitial','var')
                batinitial=0;
            end
            if ~exist('Cin','var')
                ramping=Cin;
            end
            if ~exist('etas','var')
                etas = [1 1]; %charging and discharging perfectly
            end
            obj.D=D;
            obj.state = flipud(state_initial);
            obj.battery = batinitial;
            obj.profit = zeros(L,1);
            obj.rt_sd_ct_bat = zeros(L,4);
            obj.C = Cin;
            obj.ramping=ramping;
            obj.L=L;
            obj.eta_p = etas(1);
            obj.eta_n = etas(2);
        end
       
        function obj = update(obj,pol,wind,prices,i)
        % updates based on policy recommendation
        % pol(1) - btp1, pol(2) - contract
            if i<obj.L
                btp1 = min([max([pol(1),0,obj.battery-obj.ramping]),obj.C,obj.battery+obj.ramping]);
            else
                btp1=0;
            end
            if i<obj.L-obj.D
                st = max(pol(2),0);
            else
                st=0;
            end
            rt = max(obj.eta_p*(btp1 - obj.battery),obj.eta_n*(btp1-obj.battery)) - wind + obj.state(end); 
            obj.profit(i) = prices(1)*st - max(rt*prices(2),rt*prices(3));
            obj.rt_sd_ct_bat(i,:) = [rt st btp1-obj.battery obj.battery];
            obj.state(2:end) = obj.state(1:end-1);
            obj.state(1) = st;
            obj.battery = btp1;
        end
    end
    
end
