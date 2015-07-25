clear all; clc; 
options = optimset('LargeScale','off','Display','off');

% realizations=10; 
% opt='sb';
% capacity = 0:0.5:5;
% results_file='results/sb_smallD12_G_M_S.txt';
% D = 1;
% sim_policies
% clear all;

realizations=16; 
opt='sbcp';
capacity = linspace(0,15,11);
capacity = [0,1e-2,capacity(2:end)];
results_file='results/sbcp_smallD4_G_M_S.txt';
D = 4;
sim_policies

