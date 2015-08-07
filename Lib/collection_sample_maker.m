clc; clear all; 
D=1; 
D2=4; %expansion factor. Example if want constant statistics, D = 24. We do, D = 1, D2 = 24. 
days=360;
L = days*D2*D; 
realizations = 16;
%% For 24 hour periods statistics - collecting over one year and averaging.

fpWind = fopen('../Input/Raw/Wind.csv','r'); fgetl(fpWind);
wind = fscanf(fpWind,'%*d,%*d,%f,%*f,%*f',[1 days*24]); wind = wind';
fclose(fpWind);
p_f = load('../Input/Raw/price_da.txt'); p_f=p_f';
p_r = load('../Input/Raw/price_rt.txt'); p_r=p_r';
wind = reshape(wind,24,[]);

if D<24
    wind = reshape(sum(reshape(wind,floor(24/D),[]),1),D,[]); 
    p_f = reshape(mean(reshape(p_f,floor(24/D),[]),1),D,[]);
    p_r = reshape(mean(reshape(p_r,floor(24/D),[]),1),D,[]);
end

mean_wind = mean(wind,2); sig_wind = sqrt(var(wind,0,2));
mean_p_f = mean(p_f,2); sig_p_f = sqrt(var(p_f,0,2)); 
mean_p_r = mean(p_r,2); sig_p_r = sqrt(var(p_r,0,2));

if (D==1) %stationary wind, constant prices
    sig_p_f = zeros(size(sig_p_f));
    sig_p_r = zeros(size(sig_p_r));
end

%% Generating samples
nSamples = L*realizations+D*D2*300;
nDaysSamples = floor(nSamples/D2/D);

% wind_unif = reshape(permute(repmat(wind_unif,[1 1 D2])/D2,[3 1 2]),[],2);
mean_wind = reshape(repmat(mean_wind/D2,[1 D2])',[],1);
sig_wind = reshape(repmat(sig_wind/sqrt(D2),[1 D2])',[],1);
mean_p_f = reshape(repmat(mean_p_f,[1 D2])',[],1);
mean_p_r = reshape(repmat(mean_p_r,[1 D2])',[],1);
sig_p_f = reshape(repmat(sig_p_f,[1 D2])',[],1);
sig_p_r = reshape(repmat(sig_p_r,[1 D2])',[],1);

wind_unif=mean_wind*[1 1]+0.7*sig_wind*[-1 1];
sample = [repmat(wind_unif(:,1),[nDaysSamples,1])+repmat(wind_unif(:,2)-wind_unif(:,1),[nDaysSamples,1]).*rand(nSamples,1) ... 
          repmat(mean_p_f,[nDaysSamples,1])+0.25*repmat(sig_p_f,[nDaysSamples,1]).*randn(nSamples,1) ...
          repmat(2*mean_p_r,[nDaysSamples,1])+0.25*repmat(sig_p_r,[nDaysSamples,1]).*randn(nSamples,1) ...
          repmat(0.5*mean_p_r,[nDaysSamples,1])+0.1*repmat(sig_p_r,[nDaysSamples,1]).*randn(nSamples,1)];

dlmwrite(['../Input/sample_' num2str(D) '_' num2str(D2) '.csv'],sample);

wind_mv = reshape(sample(:,1),D*D2,[]);
wind_mv = [mean(wind_mv,2) var(wind_mv,0,2)];
Eprices = [mean_p_f mean_p_r*2 mean_p_r/2];
    
Sdata=struct('wind_unif',wind_unif,'Eprices',Eprices,'wind_mv',wind_mv);
save(['../Input/Sdata_' num2str(D) '_' num2str(D2)],'Sdata');

%% Crap
% 
% sample_2004 = [wind p_f p_r*2 p_r/2];
% 
% dlmwrite('real_data\2004_sample.csv',sample_2004);
% 
% four_sample = zeros(size(sample_2004,1)/6,4);
% 
% for ind = 1:size(sample_2004,1)/6 - 1
%     four_sample(ind,:) = mean(sample_2004(1+ (ind-1)*6:ind*6,:));
% end
% 
% dlmwrite('real_data\four_sample.csv',four_sample);

%Generating probabilities on support of various wind and price processes
% four_sample = load('real_data\four_sample.csv');
% W_level = 4;
% price_level = 3;
% days=60;
% D=4;
% 
% wind_sup = [20 40 60 80];
% prices_sup = [10 46 82]';
% %wind_sup = 5+linspace(0,100,W_level);
% %prices_sup = linspace(10,100,6)'; 
% prices_sup = [prices_sup prices_sup*2 prices_sup/2];
% 
% wind_p = zeros(D,W_level);
% prices_p = zeros(price_level,D);
% 
% temp = 0:D:days*D-1;
% for ind=1:D
%     wind_p(ind,:) = hist(four_sample(ind+temp,1),wind_sup);
%     wind_p(ind,:) = wind_p(ind,:)/sum(wind_p(ind,:));
%     
%     prices_comp = four_sample(ind+temp,2:4);
%     distance_mat = zeros(days,price_level);
%     for ind2 = 1:price_level
%         distance_mat(:,ind2) = abs(prices_comp(:,1)-prices_sup(ind2,1))+(abs(prices_comp(:,2)-prices_sup(ind2,2))/2 + abs(prices_comp(:,3)-prices_sup(ind2,3))*2)/2;
%     end
%     [~,distance_min] = min(distance_mat,[],2);
%     prices_p(:,ind)=hist(distance_min,1:price_level);
%     prices_p(:,ind)=prices_p(:,ind)/sum(prices_p(:,ind));
% end
% 
% % Generating sample path
% 
% % wind_sup = [16 50 83]; 
% % wind_p = [0.441 0.254 0.305 ;
% %           0.283 0.233 0.483 ;
% %           0.450 0.183 0.367 ;
% %           0.533 0.050 0.417 ];
% %     
% % prices_sup = [ 40.000 80.000 20.000 ;
% %            80   160 40;
% %            120  240 60];
% % prices_p = [0.7800 0.3260 0.7570 0.2550;
% %             0.2105 0.5300 0.2000 0.5780;
% %             0.0095 0.1440 0.0430 0.1665]; 
% 
% wind_cp = cumsum(wind_p,2);
% prices_cp = cumsum(prices_p',2);
% 
% realizations = 100;
% D = 4; 
% days = 60*realizations;
% wind = zeros(D*days,1);
% prices = zeros(D*days,3);
% temp = 0:D:D*days-1;
% for ind = 1:D
%     L1 = repmat(rand(days,1),1,length(wind_sup));
%     L2 = repmat(wind_cp(ind,:),days,1) ;
%     [~,index] = min((L1-L2).*(L1-[zeros(days,1) L2(:,1:end-1)]),[],2);
%     wind( ind+ temp) = wind_sup (index);
%     
%     L1 = repmat(rand(days,1),1,size(prices_sup,1));
%     L2 = repmat(prices_cp(ind,:),days,1);
%     [~,index] = min((L1-L2).*(L1-[zeros(days,1) L2(:,1:end-1)]),[],2);
%     prices(ind+temp,:) = prices_sup(index,:);
% end
% 
% dlmwrite('real_data/Synth3_sample.csv',[wind prices]);
% 
% price_synth = prices_p'*prices_sup;
% dlmwrite('real_data/price_synth3.csv',price_synth);
% 
% wind_s_mean = wind_p*wind_sup';
% wind_s_var = wind_p*(wind_sup'.^2) - wind_s_mean.^2;
% wind_synth = [wind_s_mean wind_s_var];
% dlmwrite('real_data/wind_synth3.csv',wind_synth);
% 
% price_same = repmat(mean(price_synth),D,1);
% dlmwrite('real_data/price_same3.csv',price_same);
% dlmwrite('real_data/same3_sample.csv',[wind repmat(price_same,days,1)]);

% data = load('real_data/sample_four.csv');
% data = data(1:end-4,:);
% wind = reshape(data(:,1),4,[]);
% % for ind=1:4
% %     subplot(2,2,ind);
% %     hist(wind(ind,:))
% % end

% L=1e4;
% k=rand(L,1);
% cp_data = [[k (1-k)]*mean_w' repmat(mean_p,[L 1])];
% dlmwrite('real_data/sample_sbcp.csv',cp_data);
% dlmwrite('real_data/price_sbcp.csv',ones(4,1)*mean_p);
% dlmwrite('real_data/wind_sbcp.csv',ones(4,1)*[mean_w(1) var(cp_data(:,1))]);

% ncp_data = [k.*repmat(wind2(:,1),[L/4 1])+(1-k).*repmat(wind2(:,2),[L/4 1]) ...
%     repmat(Eprices,[L/4 1])+repmat(sd_p,[L/4 1]).*randn(L,3)];
% dlmwrite('real_data/sample_sb.csv',ncp_data);
% dlmwrite('real_data/price_sb.csv',Eprices);
% dlmwrite('real_data/wind_sb.csv',[mean(wind2,2) [var(ncp_data(1:4:end,1));...
%     var(ncp_data(2:4:end,1)) ; var(ncp_data(3:4:end,1)); var(ncp_data(4:4:end,1))]]);

