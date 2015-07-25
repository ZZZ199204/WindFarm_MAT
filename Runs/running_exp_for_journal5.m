clear all;
options = optimset('LargeScale','off','Display','off');
realizations=16; 
opt='sbcp';
capacity = linspace(0,12,11);
capacity = [0,1e-2,capacity(2:end)];
results_file='results/sbcp_smallD1_G_M_S.txt';
D = 1;
sim_policies