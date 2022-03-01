function [trapz_ints] = delta_sigma_mod(data)
%% Calculates the integral between two points
%
% **Usage:** [trapz_ints] = delta_sigma_mod(data)
%
% Input(s):
%   - data : Input data vector (BS data)
% Output(s):
%   - trapz_ints : Integrals using the trapezoidal rule
%
% Author: R.M.D. Kock, Leiden University

trapz_ints = zeros(size(data));
for sample=1:length(data)-1
    trapz_ints(sample) = trapz(data(sample:sample+1));
end
end
