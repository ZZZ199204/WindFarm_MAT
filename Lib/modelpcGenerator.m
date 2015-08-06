function lin_mat = modelpcGenerator(MPCParams,val_LQR)%(M,D,price_stats,wind_stats,C,beta,no_of_sims,val_LQR)
% Function generates helpful linear matrices for solving stochastic MPC
% Input: MPCParams struct holding
%   M - lookahead
%   D - period
%   prices_stats - example lookahead price values
%   wind_stats - example lookahead wind values
%   C - capacity
%   beta - discount factor
%   no_of_sims - Number of parallel look ahead paths
%   ramping - ramping constraint
%   etas - efficiency values
% val_LQR : struct holding value function in quadratic form
% Output: lin_mat 

%% Some Defaults
if ~isfield(MPCParams,'no_of_sims');MPCParams.no_of_sims =1 ; end; no_of_sims = MPCParams.no_of_sims;
if ~isfield(MPCParams,'M'); MPCParams.M = 10; end; M = MPCParams.M;
if ~isfield(MPCParams,'D'); MPCParams.D = 4; end; D = MPCParams.D;
if ~isfield(MPCParams,'prices_stats'); MPCParams.prices_stats = ones((M+1)*no_of_sims,1)*[2 3 1]; end; price_stats=MPCParams.prices_stats;
if ~isfield(MPCParams,'wind_stats'); MPCParams.wind_stats = ones((M+1)*no_of_sims,1); end; wind_stats=MPCParams.wind_stats;
if ~isfield(MPCParams,'C'); MPCParams.C = 10; end; C = MPCParams.C;
if ~isfield(MPCParams,'beta'); MPCParams.beta = 0.99; end; beta=MPCParams.beta;
if ~isfield(MPCParams,'etas'); MPCParams.etas = [1 1]; end; etas = MPCParams.etas;
if ~isfield(MPCParams,'ramping'); MPCParams.ramping = C; end; ramping = MPCParams.ramping;
if (C==0); C=1e-5; end
if (ramping==0); ramping = 1e-5; end


lin_mat = cell(D,6);

wt = zeros(no_of_sims,M+1);
prices_est = zeros(no_of_sims*3,M);

for t_start = 1:D
    
    if no_of_sims == 1
        wt = [wind_stats(t_start:D); wind_stats(1:t_start-1)]';
        wt = repmat(wt,[1,ceil(M/D)+1]);
        wt = wt(1:M+1);
        prices_est = [price_stats(t_start:D,:); price_stats(1:t_start-1,:)]';
        prices_est = repmat(prices_est,[1,ceil(M/D)]);
        prices_est = prices_est(:,1:M);
        wt = fliplr(wt);
        prices_est = fliplr(prices_est);

    else
        for ind = 1:no_of_sims
            wt(ind,:) = fliplr([wind_stats((ind-1)*M+t_start:ind*M+1); wind_stats((ind-1)*M+1:(ind-1)*M+t_start-1)]');
            prices_est(3*(ind-1)+1:3*ind,:) = fliplr([price_stats((ind-1)*M+t_start:ind*M,:); price_stats((ind-1)*M+1:(ind-1)*M+t_start-1,:)]');
        end
    end
    discount = fliplr(beta.^[0:M-1]);


    % x=[l_{M-1} -> l_{0} , bp_{M-1} -> bp_{-1} ,s_{M-1} -> s_{-D} ]
    lb_mpc = [-inf*ones(1,M), zeros(1,M+1+M+D)]'; %Lower and upper bounds
    ub_mpc = [inf*ones(1,M), C*ones(1,M+1) , 400*ones(1,M+D)]';
    lb_mpc = repmat(lb_mpc,[no_of_sims,1]);
    ub_mpc = repmat(ub_mpc,[no_of_sims,1]);

    Aeq_mpc = zeros((D+1)*no_of_sims,(3*M+D+1)*no_of_sims);
    Aeq_temp = zeros(2*(no_of_sims-1),(3*M+1+D)*no_of_sims);
    for ind = 1:no_of_sims
        Aeq_mpc((ind-1)*(D+1)+1,(ind-1)*(3*M+D+1)+2*M+1)=1; %Initial battery contraint
        Aeq_mpc((ind-1)*(D+1)+2:ind*(D+1),(ind-1)*(3*M+D+1)+3*M+2:ind*(3*M+1+D)) = eye(D); % Initial contract conditions
            
        if ind<no_of_sims
            Aeq_temp(2*(ind-1)+1,(ind-1)*(3*M+D+1)+2*M) = 1 ; Aeq_temp(2*(ind-1)+1,ind*(3*M+D+1)+2*M) = -1 ;
            Aeq_temp(2*(ind-1)+2,(ind-1)*(3*M+D+1)+3*M+1) = 1 ; Aeq_temp(2*(ind-1)+2,ind*(3*M+D+1)+3*M+1) = -1 ;
        end
    end    
    Aeq_mpc=[Aeq_mpc;Aeq_temp];

    prices_est(1:3:3*no_of_sims,1:D) = 0;
    f_st = [-prices_est(1:3:3*no_of_sims,:).*repmat(discount,[no_of_sims,1]) , zeros(no_of_sims,D)]; %From the objective futures market
    f_btp = zeros(no_of_sims,1);
    if exist('val_LQR','var')
        p = val_LQR{mod(t_start+M-1,D)+1,2}'*beta^M;
        f_st(:,1:D) = repmat(p(3:end),[no_of_sims,1]);
        f_btp = repmat(p(2),[no_of_sims,1]);
    end
    f_mpc = [repmat(discount,[no_of_sims,1]),    [ f_btp zeros(no_of_sims,M)],      f_st]';
    f_mpc = reshape(f_mpc,[no_of_sims*(3*M+1+D),1]);
    
    % Inequalities : p(b|s)_t (s_{t-D} + bp_t - bp_{t-1} - w_t) <= l_t
    
    A_mpc_1 = [ eye(M)- diag(ones(1,M-1),1) , zeros(M,1) ] ; A_mpc_1(M,M+1) = -1; %Battery difference
    A_mpc_2 = [zeros(M,D) eye(M)]; %Honouring previous contracts
    A_mpc = zeros(2*M*no_of_sims,(3*M+1+D)*no_of_sims); 
    b_mpc = zeros(2*M*no_of_sims,1);
    for ind=1:no_of_sims
        b_mpc((ind-1)*2*M+1:ind*2*M) = [wt(ind,2:M+1)  wt(ind,2:M+1)]'; %Buying price is less than l_t , selling price
        A_mpc((ind-1)*2*M+1:(ind-1)*2*M+M,(ind-1)*(3*M+D+1)+1:(ind-1)*(3*M+D+1)+M) = diag(-1./prices_est((ind-1)*3+2,:)); %Buying
        A_mpc((ind-1)*2*M+M+1:ind*2*M,(ind-1)*(3*M+D+1)+1:(ind-1)*(3*M+D+1)+M) = diag(-1./prices_est(ind*3,:)); %Selling
        A_mpc((ind-1)*2*M+1:ind*2*M,(ind-1)*(3*M+D+1)+M+1:(ind-1)*(3*M+D+1)+2*M+1) = [A_mpc_1;A_mpc_1];
        A_mpc((ind-1)*2*M+1:ind*2*M,(ind-1)*(3*M+D+1)+2*M+2:ind*(3*M+D+1)) = [A_mpc_2;A_mpc_2];
    end
    
    lin_mat{t_start,1} = f_mpc; 
    lin_mat{t_start,2} = sparse(A_mpc);
    lin_mat{t_start,3} = b_mpc; 
    lin_mat{t_start,4} = sparse(Aeq_mpc); 
    lin_mat{t_start,5} = lb_mpc; 
    lin_mat{t_start,6} = ub_mpc;

end

end



