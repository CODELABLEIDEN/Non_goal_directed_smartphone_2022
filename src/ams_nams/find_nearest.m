function [found_max, found_min] = find_nearest(x,find_value)
%% Find nearest predicted peak before and after one tap or prediction
%
% **Usage:** [found_max, found_max] = find_nearest(x,find_value)
%
% Input(s):
%   - x = array with positions of events
%   - find_value = the position of current tap or prediction
%
% Output(s):
%   - found_max = Local maxima of the nearest prediction after event
%   - found_max = Local minima of the nearest prediction before event
%
% Author: R.M.D. Kock, Leiden University

%%
data = sort(x, 'descend');
found_max = data(1);
found_min = data(end);
for idx=1:length(data)
    curr_value = data(idx);
    if curr_value > find_value && curr_value < found_max
        found_max = curr_value;
    elseif curr_value < find_value && curr_value > found_min
        found_min = curr_value;
    end
end
% first and last peak have no prediction before or after respectively
if found_min == data(end)
    found_min = NaN;
elseif found_max == data(1)
    found_max = NaN;
end
end
