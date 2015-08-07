clc; clear all; 
fnames = dir('results/*.txt');
for file = fnames'
    fp = fopen(file.name);
    header = fgetl(fp); header = [header '\tA\n'];
    data = fscanf(fp,'%f',[10 inf]); data = data'; 
    capacity = data(:,1); prof = data(:,2:end);
    asymptote = min(prof(1,3)+(prof(2,3)-prof(1,3))/(capacity(2)-capacity(1))*(capacity-capacity(1)),prof(:,1));
    fclose(fp);
    fp = fopen(['results/' file.name],'w')
    fprintf(fp,header);
    fclose(fp);
    dlmwrite(['results/' file.name],[capacity prof asymptote],'delimiter','\t','-append');
    
end