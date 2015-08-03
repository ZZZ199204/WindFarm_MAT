function pol = modelpc(M,t,y_state,price_state,D,quad_val,price_stats,wind_stats,C,beta,beta2,opt_pol)
% Computes the M step lookahead policy or model predictive control using quadratic terminal end cost
% Inputs: 
%   M - horizon which we're looking ahead
%   t - time index at which we are currently
%   state - y_t - [wt bt s_{t-1}->s_{t-D}]
%   price_state - [pf_t pb_t ps_t]
%   D - the periodicity/horizon over which decisions are made in MDP
%   quad_val - cases environment Dx3 - P,p,r for all time in period
%   price_stats - mean prices for all time in period
%   wind_stats - mean wind for all time in period
%   beta - discount factor
% Outputs: 
%   pol - policy recommendation for next state battery and contract
% Description : 
%   Solves the quadratic program (linear for high enough M) : 
%   min sum beta^t*[-pf st + l_t] + beta^M [1/2 y_{t+M}' P y_{t+M} + p'y_{t+M} + r]
%   s.t. p(b|s)_t [s_{t-D} + bp_t - bp_{t-1} - w_t] <= l_t

    t_start = mod(t,D)+1;
    
    if M == 0
        pol = opt_pol{t_start,1}*y_state + opt_pol{t_start,2};
        return
    end
    options = optimset('LargeScale','off','Display','off');

    bp_state = y_state(2);
    con_state = y_state (3:D+2);

    wt = [wind_stats(t_start:D); wind_stats(1:t_start-1)]';
    wt = repmat(wt,[1,ceil(M/D)+1]);
    wt = wt(1:M+1);
    wt(1) = y_state(1);
    % wt(2) = wind_next;
    prices_est = [price_stats(t_start:D,:); price_stats(1:t_start-1,:)]';
    prices_est = repmat(prices_est,[1,ceil(M/D)]);
    prices_est = prices_est(:,1:M);
    prices_est(:,1) = price_state';
    % prices_est(:,2) = price_next';
    wt = fliplr(wt);
    prices_est = fliplr(prices_est);
    discount = fliplr(beta.^[0:M-1]);

    % Quadratic in the end : P,p,r where V(y) = 1/2 y'Py + p'y + r
    % y=[wt,bt,s_{t-1} -> s_{t-D}]
    P = 2*quad_val{mod(t+M,D)+1,1}*beta2; %Extracting terminal quadratic 
    p = quad_val{mod(t+M,D)+1,2}*beta2;

    % x=[l_{M-1} -> l_{0} , bp_{M-1} -> bp_{-1} ,s_{M-1} -> s_{-D} ]
    lb_mpc = [-inf*ones(1,M), zeros(1,M+1+M+D)]'; %Lower and upper bounds
    ub_mpc = [inf*ones(1,M), C*ones(1,M+1) , 200*ones(1,M+D)]';

    Aeq_mpc = zeros(D+1,3*M+D+1);
    Aeq_mpc(1,2*M+1)=1; %Initial battery contraint
    Aeq_mpc(2:D+1,3*M+2:3*M+1+D) = eye(D); % Initial contract conditions
    beq_mpc = [bp_state; con_state];

    H_mpc = zeros(3*M+D+1,3*M+D+1);
    H_mpc(M+1,M+1) = P(2,2); %battery state
    H_mpc(M+1,2*M+2:2*M+1+D) = P(2,3:D+2); %Linking battery and contract
    H_mpc(2*M+2:2*M+1+D,M+1) = P(3:D+2,2); %Linking battery and contract 2
    H_mpc(2*M+2:2*M+1+D,2*M+2:2*M+1+D) = P(3:D+2,3:D+2); %Linking contract
    H_mpc = beta^(M)*(H_mpc+H_mpc')/2; %Normalize & ensure symmetry

    f_st = zeros(3,M+D);
    f_st(1,:) = [beta^M*wt(1)*( P(1,3:D+2) + P(3:D+2,1)' )/2 , zeros(1,M)]; %From the P matrix
    f_st(2,:) = [-prices_est(1,:).*discount , zeros(1,D)]; %From the objective futures market
    f_st(3,:) = [beta^M*p(3:D+2)' , zeros(1,M)]; %From the p vector
    f_btp = zeros(2,1); 
    f_btp(1) = beta^M*wt(1)*(P(1,2)+P(2,1))/2; %Linking battery and wind from P 
    f_btp(2) = beta^M*p(2); %From the p vector
    f_mpc = [discount,      sum(f_btp),zeros(1,M),      sum(f_st)]';

    % Inequalities : p(b|s)_t (s_{t-D} + bp_t - bp_{t-1} - w_t) <= l_t
    b_mpc = [wt(2:M+1)  wt(2:M+1)]'; %Buying price is less than l_t , selling price
    A_mpc_1 = [ eye(M)- diag(ones(1,M-1),1) , zeros(M,1) ] ; A_mpc_1(M,M+1) = -1; %Battery difference
    A_mpc_2 = [zeros(M,D) eye(M)]; %Honouring previous contracts
    A_mpc = zeros(2*M,3*M+1+D); 
    A_mpc(1:M,1:M) = diag(-1./prices_est(2,:)); %Buying
    A_mpc(M+1:2*M,1:M) = diag(-1./prices_est(3,:)); %Selling
    A_mpc(1:M,M+1:2*M+1) = A_mpc_1;
    A_mpc(M+1:2*M,M+1:2*M+1) = A_mpc_1;
    A_mpc(1:M,2*M+2:3*M+D+1) = A_mpc_2;
    A_mpc(M+1:2*M,2*M+2:3*M+D+1) = A_mpc_2;

    [x_mpc,~,exflag] = quadprog(H_mpc,f_mpc,A_mpc,b_mpc,Aeq_mpc,beq_mpc,lb_mpc,ub_mpc,[],options);
    pol = [x_mpc(2*M) ; x_mpc(3*M+1)];
        
end