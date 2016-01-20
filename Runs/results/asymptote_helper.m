clc; clear all; 
fnames = dir('results/24_1_results.txt');
% Sdata = load('../Input/Sdata_1_4.mat'); Sdata = Sdata.Sdata;
% factor = (Sdata.Eprices(1,1)-0.99^4*Sdata.Eprices(1,3))*(0.99^4*Sdata.Eprices(1,2)-Sdata.Eprices(1,1))/(1-0.99)/0.99^4/(Sdata.Eprices(1,2)-Sdata.Eprices(1,3))
for file = fnames'
    fp = fopen(file.name);
%     header = fgetl(fp); header = [header '\tA\n'];
    header = 'C\tG\tM\tS\tGr\tMr\tSr\tGc\tMc\tSc\tA\n';
    data = fscanf(fp,'%f',[10 inf]); data = data'; 
    capacity = data(:,1); prof = data(:,2:end);
    asymptote = min(prof(1,3)+(prof(2,3)-prof(1,3))/(capacity(2)-capacity(1))*(capacity-capacity(1)),prof(:,1));
%     asymptote2 = min(prof(1,3)+factor*(capacity-capacity(1)),prof(:,1));
    fclose(fp);
    fp = fopen(['results/' file.name],'w')
    fprintf(fp,header);
    fclose(fp);
    dlmwrite(['results/' file.name],[capacity prof asymptote],'delimiter','\t','-append');
    
end