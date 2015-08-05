function pol = modelpclinear(M,t,y_state,price_state,D,lin_mat,no_of_sims)
% Computes the M step lookahead policy or model predictive control using quadratic terminal end cost
% Inputs: 
%   M - horizon which we're looking ahead
%   t - time index at which we are currently
%   state - y_t - [wt bt s_{t-1}->s_{t-D}]
%   price_state - [pf_t pb_t ps_t]
%   D - the periodicity/horizon over which decisions are made in MDP
%   price_stats - mean prices for all time in period
%   wind_stats - mean wind for all time in period
%   beta - discount factor
% Outputs: 
%   pol - policy recommendation for next state battery and contract
% Description : 
%   Solves the quadratic program (linear for high enough M) : 
%   min sum beta^t*[-pf st + l_t] + beta^M [1/2 y_{t+M}' P y_{t+M} + p'y_{t+M} + r]
%   s.t. p(b|s)_t [s_{t-D} + eta_(p|n)*(bp_t - bp_{t-1}) - w_t] <= l_t

if ~exist('no_of_sims','var'); no_of_sims=1; end;

options = optimset('LargeScale','on','Display','off');

t_start = mod(t,D)+1;

f_mpc = lin_mat{t_start,1};
f_mpc(3*M+1:3*M+1+D:(3*M+1+D)*no_of_sims) = -price_state(1);

A_mpc = lin_mat{t_start,2};
b_mpc = lin_mat{t_start,3};
 

if size(A_mpc,1)<4*M*no_of_sims %The case without efficiency or ramping constraints
    b_mpc(M:M:end) = y_state(1);
else
    b_mpc(M:M:4*M*no_of_sims)=y_state(1);
end

for ind = 1:no_of_sims
    if size(A_mpc,1)<4*M*no_of_sims %The case without efficiency or ramping constraints
        A_mpc((ind-1)*2*M+M,(ind-1)*(3*M+D+1)+M) = -1/price_state(2);
        A_mpc(ind*2*M,(ind-1)*(3*M+D+1)+M) = -1/price_state(3);
    else
        A_mpc([(ind-1)*4*M+M,(ind-1)*4*M+3*M],(ind-1)*(3*M+D+1)+M) = -1/price_state(2);
        A_mpc([(ind-1)*4*M+2*M,ind*4*M],(ind-1)*(3*M+D+1)+M) = -1/price_state(3);
    end
end
    
beq_mpc = [repmat(y_state(2:end),[no_of_sims,1]);zeros(2*(no_of_sims-1),1)];

[x_mpc,~,exflag] = linprog(f_mpc,A_mpc,b_mpc,lin_mat{t_start,4},beq_mpc,lin_mat{t_start,5},lin_mat{t_start,6},[],options);
pol = [x_mpc(2*M) ; x_mpc(3*M+1)];
        
end