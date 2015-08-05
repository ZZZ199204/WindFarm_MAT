clear all;
addpath(genpath('../'))
addpath('/afs/.ir.stanford.edu/users/m/i/milind/Codes/WindFarm/cvx/cvx');
cvx_setup; 
p=gcp('nocreate');
if p.NumWorkers<8
    parpool(8);
end

options = optimset('LargeScale','off','Display','off');
realizations=8; 
opt='sbcp';
capacity = linspace(1,150,10);
capacity = [0,1e-2,capacity(2:end)];
results_file='results/sbcp_D24_G_M_S.txt';
D = 24;
L = D*360;
beta=0.999;
M=40;
no_of_sims=30;

sim_policies