function [deltas] = delta_mod(data)
%% Calculates the difference (delta) between two points
%
% **Usage:** [deltas] = delta_mod(data)
%
% Input(s):
%   - data : Input data vector (BS data)
% Output(s):
%   - deltas : Differences between samples from input data
%
% Author: R.M.D. Kock, Leiden University

%%
prev_sample = data(1);
deltas = zeros(size(data));
for sample=1:length(data)
    delta  = data(sample) - prev_sample;
    deltas(sample) = delta;
    prev_sample = data(sample);
end
end
