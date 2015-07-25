clear all; 
options = optimset('LargeScale','off','Display','off');
realizations=16; 
opt='sb';
capacity = linspace(0,20,11);
capacity = [0,1e-2,capacity(2:end)];
results_file='results/sb_smallD4_G_M_S.txt';
D = 4;
sim_policies