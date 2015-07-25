clear all; clc; 

options = optimset('LargeScale','off','Display','off');

realizations=16; 
opt='sb';
capacity = 0:15:150;
capacity = [0,1e-2,capacity(2:end)];
results_file='results/sb_largeD4_G_M_S.txt';
D = 4;
sim_policies

% realizations=1; 
% opt='sb';
% capacity = 150;
% % capacity = [0,1e-2,capacity(2:end)];
% results_file='temp';
% D = 4;
% sim_policies