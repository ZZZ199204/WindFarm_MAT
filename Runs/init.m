clear all; clc;
addpath(genpath('../'))

if verLessThan('matlab','8')
%     if ~matlabpool('size')
%         matlabpool(2);
%     end
else
    addpath('/afs/.ir.stanford.edu/users/m/i/milind/Codes/WindFarm/cvx/cvx'); 
    cvx_setup;
    poolobj = gcp('nocreate'); % If no pool, do not create new one.
    if isempty(poolobj) || (poolobj.NumWorkers<8)
        parpool(8);
    end
end

options = optimset('LargeScale','off','Display','off');