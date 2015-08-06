function price_LQR = fitPrice(prices_stats,params)
% fixing quadratics for the price processes for the LQG approximation
% Inputs: 
%   prices_stats : period x 3 [pf pb ps]
%   params : struct holding D, max_wind and C. Latter two are optional
% Outputs: coefficents of quadratic for each time period

    if ~exist('prices_stats','var'); prices_stats = ones(4,1)*[1 3 2]; end
    if ~exist('params','var'); params = struct; end
    if ~isfield(params,'D'); params.D = 4; end

    
    price_LQR = zeros(params.D,4);
    
    if isfield(params,'C') && isfield(params,'max_wind')
        max_st = params.max_wind+params.C/5;
        x1=linspace(-max_st/10,max_st,100)'; 
        x2 = [linspace(-max_st/3.5,max_st/3,100)]';
    else
         x1 = [-10:0.1:70]';
         x2 = [-30:0.1:40]';
    end
    
    for ind = 1:params.D 
        future_price = -prices_stats(ind,1)*5*min(x1,0) - prices_stats(ind,1)*max(x1,0);
        const = [x1.^2 2*x1]\future_price;
        price_LQR(ind,1) = const(1); price_LQR(ind,2) = const(2)/const(1);

        real_price = max(prices_stats(ind,2)*x2,prices_stats(ind,3)*x2);
        const = [x2.^2 2*x2]\real_price;
        price_LQR(ind,3) = const(1); price_LQR(ind,4)=const(2)/const(1);
    end

end    