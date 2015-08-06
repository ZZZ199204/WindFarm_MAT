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
        etas; %efficiency while [charging discharging]
    end
    
    methods
        function obj = pol_sim(params)
        % constructor
            if ~exist('params','var'); params=struct; end
            if ~isfield(params,'D'); params.D = 4; end
            if ~isfield(params,'L'); params.L = 240; end
            if ~isfield(params,'C'); params.C = 10; end
            if ~isfield(params,'state_initial'); params.state_initial = zeros(params.D,1); end
            if ~isfield(params,'batinitial'); params.batinitial = 0; end
            if ~isfield(params,'ramping'); params.ramping = params.C; end
            if ~isfield(params,'etas'); params.etas = [1 1]; end
            
            obj.D=params.D;
            obj.state = flipud(params.state_initial);
            obj.battery = params.batinitial;
            obj.profit = zeros(params.L,1);
            obj.rt_sd_ct_bat = zeros(params.L,4);
            obj.C = params.C;
            obj.ramping=params.ramping;
            obj.L=params.L;
            obj.etas = params.etas;
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
            rt = max(obj.etas(1)*(btp1 - obj.battery),obj.etas(2)*(btp1-obj.battery)) - wind + obj.state(end); 
            obj.profit(i) = prices(1)*st - max(rt*prices(2),rt*prices(3));
            obj.rt_sd_ct_bat(i,:) = [rt st btp1-obj.battery obj.battery];
            obj.state(2:end) = obj.state(1:end-1);
            obj.state(1) = st;
            obj.battery = btp1;
        end
    end
    
end
