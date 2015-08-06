init;

realizations=16; 
opt='4_1';
capacity = [0 1e-2 linspace(1,150,7)];
D = 4;
L = 240;
beta=0.99;
M=10;
no_of_sims=30;

etas_array = [1 1; 1.1 0.9; 1.2 0.8; 1.5 0.5];

for iEta=1:size(etas_array,1)
    etas = etas_array(iEta,:);
    results_file=sprintf('results/%s_eta_%0.1f_%0.1f.txt',opt,etas(1),etas(2));
    sim_policies
end