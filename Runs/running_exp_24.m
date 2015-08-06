init;

realizations=16; 
opt='24_1';
capacity = [0 linspace(1e-2,20,7) linspace(20,150,7) linspace(200,500,4)];
D = 24;
L = D*360;
beta=0.999;
M=48;
no_of_sims=40;
results_file=sprintf('results/%s_results.txt',opt);
sim_policies