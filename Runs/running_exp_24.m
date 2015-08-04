clear all;
addpath(genpath('..\'))
parpool(8);

options = optimset('LargeScale','off','Display','off');
realizations=8; 
opt='sbcp';
capacity = linspace(0,12,11);
capacity = [0,1e-2,capacity(2:end)];
results_file='results/sbcp_smallD24_G_M_S.txt';
D = 24;
L = 
sim_policies