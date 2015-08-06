init;

realizations=16; 
opt='1_4';
capacity = [0 linspace(1e-2,20,7) linspace(20,150,7) linspace(200,500,4)];
D = 1;
L = 60;
beta=0.99;
M=10;
no_of_sims=30;
results_file=sprintf('results/%sD1_results.txt',opt);
sim_policies