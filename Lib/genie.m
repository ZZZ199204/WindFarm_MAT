function genieOut = genie(wind,prices,params)
% Genie upper bound
% Inputs: 
%   wind: wind in the period
%   prices: prices in the period of interest
%   params: struct holding -
%   D,C,beta,batinitial,contract_initial,ramping,etas
% Output: 
%   genieOut: struct holding - btp1,st,profit,rt_market,tot_profit,ramping
%   sensitivity

%% Defaults and initialization
if ~exist('params','var'); params = struct; end 
if ~isfield(params,'D'); params.D = 4; end; D=params.D;
if ~isfield(params,'C'); params.C = 10; end; C = params.C;
if ~isfield(params,'beta'); params.beta = 0.999; end; beta = params.beta;
if ~isfield(params,'batinitial'); params.batinitial = 0; end; batinitial = params.batinitial; 
if ~isfield(params,'L'); params.L = 240; end; L = params.L;
if ~isfield(params,'state_initial'); params.state_initial = zeros(params.D,1); end; contract_initial = params.state_initial; 
if ~isfield(params,'ramping'); params.ramping = params.C; end; ramping = params.ramping; 
if ~isfield(params,'etas'); params.etas = [1 1]; end; etas = params.etas;
if ~exist('wind','var'); wind = ones(params.L,1); end
if ~exist('prices','var'); prices = ones(params.L,1)*[1 3 2]; end
if (C==0); C = 1e-3; end

%% running the genie optimization

    discount = beta.^(0:L-1);
    
    cvx_begin quiet
        variables st(L,1) btp1(L,1)
        dual variable dual_ramp
        expression rt_market
        rt_market = [contract_initial;st(1:L-D)]+max(etas(1)*(btp1-[batinitial;btp1(1:end-1)]),etas(2)*(btp1-[batinitial;btp1(1:end-1)])) - wind ;
        minimize ( discount*(-prices(:,1).*st + max(prices(:,2).*rt_market,prices(:,3).*rt_market)  ) )
        subject to
            rt_market(D+1:end) <= 0
            st >= 0
            btp1 <= C
            btp1 >= 0
            st(L-D+1:end) == 0
            st<=1e3
            dual_ramp : norm(btp1 - [batinitial ; btp1(1:end-1)],Inf) <= ramping
    cvx_end
    profit = - (-prices(:,1).*st + max(prices(:,2).*rt_market,prices(:,3).*rt_market));
    tot_profit = discount*profit;         
    
    genieOut = struct('btp1',btp1,'st',st,'profit',profit,'rt_market',rt_market,'tot_profit',tot_profit,'dual_ramp',dual_ramp);
end