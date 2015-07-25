classdef pol_sim
%For each run, stores essential things and has an update method

    properties
        state; %newest to oldest
        battery; 
        profit;
        rt_sd_ct_bat;
        C;
        ramping;
        D;
        L;
    end
    
    methods
        function obj = pol_sim(D,L,Cin,state_initial,batinitial,ramping)
        % constructor
            if nargin<4
                state_initial=zeros(D,1);
            end
            if nargin<5
                batinitial=0;
            end
            if nargin<6
                ramping=Cin;
            end
            obj.D=D;
            obj.state = flipud(state_initial);
            obj.battery = batinitial;
            obj.profit = zeros(L,1);
            obj.rt_sd_ct_bat = zeros(L,4);
            obj.C = Cin;
            obj.ramping=ramping;
            obj.L=L;
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
            rt = btp1 - obj.battery - wind + obj.state(end); 
            obj.profit(i) = prices(1)*st - max(rt*prices(2),rt*prices(3));
            obj.rt_sd_ct_bat(i,:) = [rt st btp1-obj.battery obj.battery];
            obj.state(2:end) = obj.state(1:end-1);
            obj.state(1) = st;
            obj.battery = btp1;
        end
    end
    
end
