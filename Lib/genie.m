% Genie upper bound
function [btp1,st,profit,rt_market,tot_profit,dual_ramp] = genie(wind,prices,D,C,beta,batinitial,contract_initial,ramping,etas)
    if ~exist('ramping','var')
        ramping = C;
    end
    if ~exist('etas','var')
        etas = [1 1];
    end
    if C==0
        C = 1e-3;
    end
    
    L = size(prices,1);
    discount = beta.^[0:L-1];
    
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
    
end