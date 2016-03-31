init;


opt='4_1';
D = 4;
capacity = [0 linspace(1e-2,20,3) linspace(30,150,4) linspace(200,500,3)];
realizations=16; 
% realizations = 1;
% results_file=sprintf('results/%s_results_trace.rxt',opt); overwrite=1;
% capacity = 30;
% L=120*D


beta=0.99;
M=48;
no_of_sims=40;
L = 360*D;
results_file=sprintf('results/%s_results.txt',opt); overwrite = 1;
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