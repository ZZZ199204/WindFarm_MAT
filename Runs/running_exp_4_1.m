init;

realizations=16; 
opt='4_1';
capacity = [0 linspace(1e-2,20,7) linspace(20,150,7) linspace(200,500,4)];
D = 4;
L = 240;
beta=0.99;
M=10;
no_of_sims=30;
results_file=sprintf('results/%s_results.txt',opt);
sim_policies

%% crap 
% realizations=16; 
% opt='sb';
% capacity = 0:15:150;
% capacity = [0,1e-2,capacity(2:end)];
% results_file='results/sb_largeD4_G_M_S.txt';
% D = 4;
% sim_policies

% clear all; 
% options = optimset('LargeScale','off','Display','off');
% realizations=16; 
% opt='sb';
% capacity = linspace(0,20,11);
% capacity = [0,1e-2,capacity(2:end)];
% results_file='results/sb_smallD4_G_M_S.txt';
% D = 4;
% sim_policies