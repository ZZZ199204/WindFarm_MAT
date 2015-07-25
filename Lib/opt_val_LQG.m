function [opt_pol,opt,convergence] = opt_val_LQG(D,Th,prices,wind,C,beta,bat_const)
% Function computes the optimal policy and function value
% Input
%     D: Futures pricing period
%     Th: Horizon over which DP is computed
%     prices: [pf1 pf2 pr1 pr2] for time period D. If same, vector input
%     wind: wt independent normal[mu sig]. For time period D. 
%     C: Capacity of the battery
%     beta : Contraction coefficient in discounted pricing
%     bat_const : Constant in cost function for finite battery. Default 1.
% Output
%     opt_pol : btp1, sd as an affine function of the state, time. U1_t*x
%     +u2_t
%     opt : Value function as a quadratic function of the state, time.
%     x'V1_tx + x'v2_t + v3_t . 
% Details
%     Dynamic Program. LQG recursion 
    
    % Defaults for constants
    if nargin<7
        bat_const = 1;
    end
    if nargin<6
        beta = 1;
    end
    
    if size(prices,1)<D %If there is no variation from day to day
        prices = repmat(prices,[D,1]);
    end
    if size(wind,1)<D
        wind = repmat(wind,[D,1]);
    end
    
    % State x_t = [wt bt s_(t-1) s_(t-2) ... s_(t-D)]
    % Input ut = [btp1,st]
    % x_(t+1) = A xt + B ut + b wt
    A = zeros(D+2,D+2); A(sub2ind(size(A),4:D+2,3:D+1)) = 1; 
    B = zeros(D+2,2); B(2,1) = 1; B(3,2) = 1;
    b = zeros(D+2,1); b(1) = 1;
    
    %gt = pf1 (st + pf2)^2 -pf1*pf2^2+ pr1(sd + ct - wt + pr2 )^2-pr1*pr2^2 + bat_const(btp1-C/2)^2
    %gt = pf1*(a3*ut + pf2)^2 - pf1*pf2^2 + pr1(a1*xt + a2*ut + pr2)^2 - pr1*pr2^2 + bat_const(a2*ut - C/2)^2
    %gt = [xt; ut]' [Q11 Q12 ; Q21 Q22] [xt;ut] + [q1' q2'][xt; ut] + s
    
    a1 = zeros(D+2,1); a1(D+2)=1; a1(1) = -1; a1(2)= -1; 
    a2 = [1;0];
    a3 = [0;1];
    
    Q11a = a1*a1';
    Q12a = a1*a2'; 
    Q22a = a2*a2';
    Q22b = a3*a3';
    q1a = 2*a1;
    q2a = 2*a2;
    q2b = 2*a3;   
    s = C^2/4*bat_const;
       
    %Returning optimal policy and value function
    opt_pol = cell(D,2);
    opt = cell(D,3);
    
    %Initial V is zero. V = x'Px + x'p + r  . 
    P = zeros(D+2,D+2); p = zeros(D+2,1); r=0;
    
    convergence = zeros(Th+1,1);
    ind = Th;
    while ind>=0
        Pold = P; 
        
        %Time varying cost function parameters
        t = mod(ind,D)+1;
        Q11 = prices(t,3)*Q11a;
        Q12 = prices(t,3)*Q12a;
        Q22 = (prices(t,3)+bat_const)*Q22a + prices(t,1)*Q22b;
        q1 = prices(t,3)*prices(t,4)*q1a;
        q2 = prices(t,1)*prices(t,2)*q2b + (prices(t,3)*prices(t,4)-bat_const*C/2)*q2a;

        %Recursive equation RHS = u'Mu + u'(Nx+O) + x'Tx + x'U + v
        M = Q22 + B'*P*B*beta;
        N = 2*(Q12' + B'*P*A*beta);
        O = q2 + (2*wind(t,1)*B'*P*b + B'*p)*beta;
        T = Q11 + A'*P*A*beta;
        U = q1 + (2*wind(t,1)*A'*P*b + A'*p)*beta;
        v = s + (r + wind(t,2)*b'*P*b + wind(t,1)*p'*b)*beta;
        Minv = pinv(M);

        %Recursive updates
        P = -1/4*N'*Minv*N + T;
        p = -1/2*N'*Minv*O + U;
        r = -1/4*O'*Minv*O + v;

        %Saving the matrices obtained       
        if t <= D
            opt_pol{t,1} = -1/2*Minv*N;
            opt_pol{t,2} = -1/2*Minv*O;
            opt{t,1} = P;
            opt{t,2} = p;
            opt{t,3} = r;
        end
        
        ind = ind-1;
        
    end
    convergence = norm(P-Pold);
end
