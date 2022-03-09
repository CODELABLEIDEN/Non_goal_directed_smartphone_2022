function [x] =  create_design_matrix_model(EEG1)
num_params = 4;
% initialize with size (num events, number of parameters)
x = zeros(length(EEG1),num_params);
% categorical variables 
x(:,1) = [EEG1.AMs_i];
x(:,2) = [EEG1.NAMs_i];
% continous variables
x(:,3) = nanzscore(log10(abs([EEG1.pks])));
% Intercept
x(:,end) = ones(length(EEG1),1);
end 