%% Running the experiment with real data
init;

D=24; 
realizations=12; 
error_const=0.3;
capacity = [0 linspace(1e-2,20,3) linspace(30,150,4) linspace(200,500,3)];
L = 60*D;
beta=0.99;
M=25;
no_of_sims=5;

sim_policies_real