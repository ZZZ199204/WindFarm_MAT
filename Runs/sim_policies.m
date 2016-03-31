if ~exist('opt','var'); opt='4'; end
if ~exist('results_file','var'); results_file='temp'; end
if ~exist('capacity','var'); capacity = 0:50:150; end
if ~exist('realizations','var'); realizations = 1; end
if ~exist('D','var'); D=4; end
if ~exist('L','var'); L = 240; end
if ~exist('beta','var'); beta=0.999; end
if ~exist('etas','var'); etas=[1 1]; end
if ~exist('ramping','var'); ramping = 1; end
if ~exist('batinitial','var'); batinitial = 0; end
if ~exist('beta2','var'); beta2 = 1; end
if ~exist('M','var'); M = 10; end
if ~exist('no_of_sims','var'); no_of_sims = 30; end
discount = beta.^(0:L-1);

data_file=['../Input/sample_',opt,'.csv'];
sdata_file=['../Input/Sdata_',opt];

Mdata = load(data_file);
wind = Mdata(:,1);
prices = Mdata(:,2:4);

Sdata=load(sdata_file); Sdata=Sdata.Sdata; 
Sdata.D=D; Sdata.beta=beta; 

% Fitting quadratics for the LQG
wind_LQR = Sdata.wind_mv;
prices_LQR = fitPrice(Sdata.Eprices,struct('D',D));
Th = 1e4;
prices_stats = [Sdata.Eprices; prices(L*realizations+1:end,:)];
wind_stats = [wind_LQR(:,1);wind(L*realizations+1:end,:)];

wind = reshape(wind(1:L*realizations),L,realizations);
prices = permute(reshape(prices(1:L*realizations,:),L,realizations,3),[1 3 2]);

if ~exist('contract_initial','var')
    contract_initial = zeros(D,1);
    for ind=1:D
        temp = opt_small_battery(Sdata,ind-1,zeros(D+2,1),prices_stats(ind,:));
        contract_initial(ind,1)=temp(2);
    end
end

%% Running the main simulations
prof = zeros(length(capacity),9);

sysParams = struct('M',M,'D',D,'no_of_sims',no_of_sims,...
    'beta',beta,'beta2',beta2,'L',L,'prices_stats',prices_stats,'wind_stats',wind_stats,'etas',etas,...
    'state_initial',contract_initial,'batinitial',batinitial);
        lqg_la = pol_sim(sysParams);
        sb_pol = pol_sim(sysParams); 

for cap_ind = 1:length(capacity)
    C = capacity(cap_ind)
    ramping_C = ramping*C;
    Sdata.C=C;
    
    % LQG policy
    [opt_pol_LQR,val_LQR,~] = opt_val_LQG(D,Th,prices_LQR,wind_LQR,C,beta,5/(C+1));
    
    sysParams.C=C;sysParams.ramping=ramping_C;
    if (etas(1)>1+1e-5) || (ramping<1-1e-5)
        lin_mat = MPCGeneratorEfficiency(sysParams,val_LQR);
    else
        lin_mat = modelpcGenerator(sysParams,val_LQR);
    end
    
    profind2=zeros(realizations,9);

    for iRealizations=1:realizations
        iRealizations
        lqg_la = pol_sim(sysParams);
        sb_pol = pol_sim(sysParams);
        wind_realization = wind(:,iRealizations);
        prices_realization = prices(:,:,iRealizations);
      
        for ind = 1:L
            %Implementing any step lookahead verification
            temp = modelpclinear(M,ind-1,[wind_realization(ind);lqg_la.battery;lqg_la.state]...
                ,prices_realization(ind,:),D,lin_mat,no_of_sims);
            lqg_la=lqg_la.update(temp,wind_realization(ind),prices_realization(ind,:),ind);

            %Implementing the small battery policy
            temp = opt_small_battery(Sdata,ind-1,[wind_realization(ind);sb_pol.battery;sb_pol.state],prices_realization(ind,:));
            sb_pol = sb_pol.update(temp,wind_realization(ind),prices_realization(ind,:),ind);
         end
        %Genie Policy
        genieOut = genie (wind_realization,prices_realization,sysParams);   
        
        profind2(iRealizations,:) = [genieOut.tot_profit discount*[lqg_la.profit sb_pol.profit ...
            abs([genieOut.rt_market lqg_la.rt_sd_ct_bat(:,1) sb_pol.rt_sd_ct_bat(:,1)]) ...
            genieOut.st lqg_la.rt_sd_ct_bat(:,2) sb_pol.rt_sd_ct_bat(:,2)]];
    end
    prof(cap_ind,:) = sum(profind2,1)/realizations;
end

if length(capacity)>=2
    asymptote = min(prof(1,3)+(prof(2,3)-prof(1,3))/(capacity(2)-capacity(1))*(capacity-capacity(1)),prof(:,1));
else
    asymptote = prof(1,1);
end
if exist('overwrite','var')
    if (overwrite==1)
        fResult = fopen(results_file,'w');
         fprintf(fResult,'C\tG\tM\tS\tGr\tMr\tSr\tGc\tMc\tSc\tA\n');
        fclose(fResult);
    end
end
dlmwrite(results_file,[capacity' prof asymptote],'delimiter','\t','-append');
% dlmwrite(results_file,[capacity' prof],'delimiter','\t','-append');
%% Crap
% [winAR,~] = genStatsAR();
%     lin_mat =
%     modelpcGenerator(M,D,prices_stats,wind_stats,C,beta,no_of_sims,val_LQR);
%     temp = modelpc(M,ind-1,[wind(indc);lqg_la.battery;lqg_la.state],...
%     prices(indc,:),D,val_LQR,prices_stats,wind_LQR(:,1),C,beta,beta2,...
%     opt_pol_LQR);
%     temp = mpc_ar(M,ind-1,[wind(ind+ind2*L);lqg_ar.battery;lqg_ar.state],prices(ind+ind2*L,:),D,val_LQR2,prices_stats,winAR,C,beta,1.5,opt_pol_LQR2);

        %Implementing affine policy lookahead policy
%         temp = modelpc(0,ind-1,[wind(indc);lqg_ap.battery;lqg_ap.state],...
%             prices(indc,:),D,val_LQR,prices_stats,wind_LQR(:,1),C,beta,beta2,...
%             opt_pol_LQR);
%         lqg_ap=lqg_ap.update(temp,wind(indc),prices(indc,:),ind);
        
        %Implementing the discrete lookahead policy
%         temp = opt_discrete_la(Vdata,ind-1,prices(indc,:),[-wind(indc)-dis_la.battery+...
%             dis_la.state(end);dis_la.state(1:end-1)],1);
%         dis_la=dis_la.update(temp,wind(indc),prices(indc,:),ind);

% discrete = load('results/sims_line');
% plot(capacity,prof); hold on; 
% plot(discrete(:,1),-discrete(:,2));
% legend('Clairvoyant','MPC','SB');
% xlabel('Capacity')
% ylabel('Discounted profit')