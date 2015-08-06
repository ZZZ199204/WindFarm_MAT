init;

realizations=8; 
opt='24_1';
capacity = [200 500];%linspace(0,500,7);
D = 24;
L = D*60;
beta=0.999;
M=48;
no_of_sims=40;
results_file=sprintf('results/%s_results.txt',opt);
sim_policies