function price_LQR = fitPrice(prices_stats,max_wind,C)
% fitting price for LQR problems    
    D = size(prices_stats,1);
    price_LQR = zeros(D,4);
    
    if nargin<2
         x1 = [-10:0.1:70]';
         x2 = [-30:0.1:40]';
    else
        max_st = max_wind+C/5;
        x1=linspace(-max_st/10,max_st,100)'; 
        x2 = [linspace(-max_st/3.5,max_st/3,100)]';
    end
    for ind = 1:D 
        future_price = -prices_stats(ind,1)*5*min(x1,0) - prices_stats(ind,1)*max(x1,0);
        const = [x1.^2 2*x1]\future_price;
        price_LQR(ind,1) = const(1); price_LQR(ind,2) = const(2)/const(1);

        real_price = max(prices_stats(ind,2)*x2,prices_stats(ind,3)*x2);
        const = [x2.^2 2*x2]\real_price;
        price_LQR(ind,3) = const(1); price_LQR(ind,4)=const(2)/const(1);
    end

end    