init;

realizations=8; 
opt='4_1';
capacity = [0 linspace(1,150,6) linspace(200,500,3)];
D = 4;
L = 240;
beta=0.99;
M=10;
no_of_sims=25;
ramping_array = linspace(0.1,1,4);
etas=[1 1];
for iRamping=1:length(ramping_array)
    ramping = ramping_array(iRamping);
    results_file=sprintf('results/%s_ramping_%0.1f.txt',opt,ramping);
    sim_policies
end