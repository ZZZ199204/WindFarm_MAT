%% Running the experiment with real data
init;

D=4; 
% realizations = 1;
% capacity = [0 20 150 500];
error_const=0.1;
realizations=12; 
capacity = [0 linspace(1e-2,20,3) linspace(30,150,4) linspace(200,500,3)];
L = 60*D;
% L = 10;
beta=0.99;
M=30;
no_of_sims=30;
beta2=1e-40;
sim_policies_real