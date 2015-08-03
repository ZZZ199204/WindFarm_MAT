if ~exist('opt','var')
    opt='sb';
end
    
if ~exist('results_file','var')
    results_file='temp';
end

wind_file=['real_data/wind_',opt,'.csv'];
prices_file=['real_data/price_',opt,'.csv'];
data_file=['real_data/sample_',opt,'.csv'];
sdata_file=['real_data/Sdata_',opt];

% [winAR,~] = genStatsAR();

Mdata = load(data_file);
wind = Mdata(:,1);
prices = Mdata(:,2:4);


if ~exist('capacity','var')
    capacity = 0:50:150;
end
if ~exist('realizations','var')
    realizations = 1;
end
if ~exist('D','var')
    D=4;
end
if ~exist('L','var'); L = 240; end
if ~exist('beta','var'); beta=0.99; end

discount = beta.^[0:L-1];
batinitial = 0;
 
beta2 = 1;
if ~exist('M','var'); M = 10; end
if ~exist('no_of_sims','var'); no_of_sims = 30; end

% Fitting quadratics for the LQG
wind_LQR = load(wind_file);
Th = 1e4;
prices_stats = load(prices_file);
price_LQR = zeros(D,4);

prices_stats = [prices_stats; prices(D*100+1:end,:)];
wind_stats = [wind_LQR(:,1);wind(D*100+1:end,:)];
price_LQR = fitPrice(prices_stats);

Sdata=load(sdata_file); Sdata=Sdata.Sdata; Sdata.D=D;

for ind=1:D
    temp = opt_small_battery(Sdata,ind-1,zeros(D+2,1),prices_stats(ind,:));
    contract_initial(ind,1)=temp(2);
%     contract_initial(ind,1)=1;
end


%Running the main simulations
prof = zeros(length(capacity),9);

for cap_ind = 1:length(capacity)
    C = capacity(cap_ind)
    Sdata.C=C;
    
    % LQG policy
    [opt_pol_LQR,val_LQR,c] = opt_val_LQG(D,Th,price_LQR,wind_LQR,C,beta,5/(C+1));
    lin_mat = modelpcGenerator(M,D,prices_stats,wind_stats,C,beta,no_of_sims,val_LQR);

    profind2=zeros(realizations,9);
%     a11=zeros(L,realizations);
%     a12=zeros(size(a11));
%     a13=zeros(size(a11));
%     a14=zeros(size(a11));
    parfor ind2=0:(realizations-1)
        ind2
        lqg_la = pol_sim(D,L,C,contract_initial,0);
        sb_pol = pol_sim(D,L,C,contract_initial,0);
        
    for ind = 1:L
        t_F = mod(ind-1,D);
        indc = ind2*L+ind;

        %Implementing any step lookahead verification
%         temp = modelpc(M,ind-1,[wind(indc);lqg_la.battery;lqg_la.state],...
%             prices(indc,:),D,val_LQR,prices_stats,wind_LQR(:,1),C,beta,beta2,...
%             opt_pol_LQR);
        temp = modelpclinear(M,ind-1,[wind(indc);lqg_la.battery;lqg_la.state],...
            prices(indc,:),D,lin_mat,no_of_sims);
%         temp = mpc_ar(M,ind-1,[wind(ind+ind2*L);lqg_ar.battery;lqg_ar.state],prices(ind+ind2*L,:),D,val_LQR2,prices_stats,winAR,C,beta,1.5,opt_pol_LQR2);
        lqg_la=lqg_la.update(temp,wind(indc),prices(indc,:),ind);
        
        %Implementing affine policy lookahead policy
%         temp = modelpc(0,ind-1,[wind(indc);lqg_ap.battery;lqg_ap.state],...
%             prices(indc,:),D,val_LQR,prices_stats,wind_LQR(:,1),C,beta,beta2,...
%             opt_pol_LQR);
%         lqg_ap=lqg_ap.update(temp,wind(indc),prices(indc,:),ind);
        
        %Implementing the discrete lookahead policy
%         temp = opt_discrete_la(Vdata,ind-1,prices(indc,:),[-wind(indc)-dis_la.battery+...
%             dis_la.state(end);dis_la.state(1:end-1)],1);
%         dis_la=dis_la.update(temp,wind(indc),prices(indc,:),ind);

        %Implementing the small battery policy
        temp = opt_small_battery(Sdata,ind-1,[wind(indc);sb_pol.battery;...
            sb_pol.state],prices(indc,:));
        sb_pol = sb_pol.update(temp,wind(indc),prices(indc,:),ind);
        

    end

    %Genie Policy
    [batp1,st,profit_detail,rt_market,temp1,~] = genie (wind(ind2*L+1:(ind2+1)*L),...
        prices(ind2*L+1:(ind2+1)*L,:),D,C,beta,batinitial,contract_initial);   
    
% %     if temp1 > 1e10
%         a11(:,ind2+1)=rt_market; a12(:,ind2+1)=profit_detail; a13(:,ind2+1)=st; a14(:,ind2+1)=batp1;
% %     end
    
    profind2(ind2+1,:) = [temp1 discount*[lqg_la.profit sb_pol.profit ...
        abs([rt_market lqg_la.rt_sd_ct_bat(:,1) sb_pol.rt_sd_ct_bat(:,1)]) ...
        st lqg_la.rt_sd_ct_bat(:,2) sb_pol.rt_sd_ct_bat(:,2)]];
    end
    prof(cap_ind,:) = sum(profind2,1)/realizations;
end

% discrete = load('results/sims_line');
% plot(capacity,prof); hold on; 
% plot(discrete(:,1),-discrete(:,2));
% legend('Clairvoyant','MPC','SB');
% xlabel('Capacity')
% ylabel('Discounted profit')

fp = fopen(results_file,'w');
fprintf(fp,'C\tG\tM\tS\tGr\tMr\tSr\tGc\tMc\tSc\n');
fclose(fp);
dlmwrite(results_file,[capacity' prof],'delimiter','\t','-append');