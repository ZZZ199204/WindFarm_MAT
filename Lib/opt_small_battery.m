function [opt_pol] = opt_small_battery(Sdata,t,state,prices)
% Function computes the optimal policy for small battery
% Input
%     Sdata : struct holding D, C, expected prices and wind (uniformly distributed) statistics
%     t : time index we're at
%     prices: [pf pb ps] right now
%     state : [w;b ; states(newest:oldest)] 
% Output
%     opt_pol : btp1, sd 

if ~exist('Sdata','var'); Sdata=struct; end
if ~isfield(Sdata,'D'); Sdata.D=4; end
if ~isfield(Sdata,'Eprices'); Sdata.Eprices = ones(Sdata.D,1)*[1 3 2]; end
if ~isfield(Sdata,'wind_unif'); Sdata.wind_unif = ones(Sdata.D,1)*[1 2]; end
if ~isfield(Sdata,'C'); Sdata.C = 10; end

    tnow=mod(t,Sdata.D)+1;
    tfut=mod(t+Sdata.D,Sdata.D)+1;

    deficit = state(end)-state(1)-state(2);
    if deficit>0
        opt_pol(1,1) = 0;
    else
        opt_pol(1,1) = min(-deficit,Sdata.C);
    end
    s_ratio = (prices(1)/Sdata.beta^Sdata.D - Sdata.Eprices(tfut,3))/...
        (Sdata.Eprices(tfut,2)-Sdata.Eprices(tfut,3));
    opt_pol(1,2) = Sdata.wind_unif(tfut,1)*(1-s_ratio)+Sdata.wind_unif(tfut,2)*s_ratio;        
    
end
