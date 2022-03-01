function [distance_maxs, distance_mins, maxs, mins, types] = find_nearest_distances(all_2_find,latencies, taps)
%% Find nearest predicted peak before and after all taps or predictions
%
% **Usage:** [distance_maxs, distance_mins, maxs, mins, types] = find_nearest_distances(all_2_find,latencies,taps)
%
% Input(s):
%   - all_2_find = position of events (either taps or predictions)
%   - latencies = latencies of all the predicted events
%   - taps = position of taps
%
% Output(s):
%   - distance_maxs = Position (index) of the nearest predicted peaks after event
%   - distance_mins = Position (index) of the nearest predicted peaks  before event
%   - maxs = Local maxima of the nearest predicted peaks after event
%   - mins = Local minima of the nearest predicted peaks before event
%   - types = cell array types of nearest events
%       - types{1,i} = type of nearest event before current event;
%       - types{2,i} = type of nearest event after current event;
%
% Requires:
%   - find_nearest
%
% Author: R.M.D. Kock, Leiden University

%%
distance_maxs = []; distance_mins = []; maxs = []; mins = []; types = {};
for i=1:length(latencies)
    [found_max, found_min] = find_nearest(all_2_find,latencies(i));
    distance_maxs = [distance_maxs found_max-latencies(i)];
    distance_mins = [distance_mins latencies(i)-found_min];
    maxs = [maxs found_max];
    mins = [mins found_min];

    % find distance to taps near a prediction
    [found_max_a, found_max_b] = find_nearest(taps,found_max);
    after = min([found_max-found_max_b, found_max_a-found_max]);
    [found_min_a, found_min_b] = find_nearest(taps,found_min);
    before = min([found_min-found_min_b, found_min_a-found_min]);
    prediction_before_type = 'NA';
    prediction_after_type = 'NA';
    if (after<=100)
        prediction_after_type = 'AM';
    elseif (after>=1000)
        prediction_after_type = 'NAM';
    end

    if (before<=100)
        prediction_before_type = 'AM';
    elseif (before>=1000)
        prediction_before_type = 'NAM';
    end
    types{1,i} = prediction_before_type;
    types{2,i} = prediction_after_type;
end
end
