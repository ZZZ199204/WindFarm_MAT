clear all;
options = optimset('LargeScale','off','Display','off');
realizations=16; 
opt='sbcp';
capacity = 0:15:150;
capacity=[0,1e-2,capacity(2:end)];
results_file='results/sbcp_largeD4_G_M_S.txt';
D = 4;
sim_policies