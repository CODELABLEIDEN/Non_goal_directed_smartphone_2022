function [s] = find_ams_n_nams(taps, params, precision_am, vicinity)
%% Find the position of ams and nams
%
% **Usage:** [s] = find_ams_n_nams(taps, params, precision_am, vicinity)
%
% Input(s):
%   - taps = position of real taps
%   - params = cell with the results of findpeaks, peak local maxima and location
%   - precision_am = int which denotes the distance a tap can be from the
%     position of a predicted tap to define an AM-- AMs are any prediction where
%     predicted local maxima is within 100 ms of real tap
%   - vicinity = int which denotes the distance a tap can be from the
%     position of a predicted tap to define a NAM-- NAMs are any prediction
%     further than 1000 ms from a real tap
%
% Output(s):
%   - s = struct with position of AMs and NAMs
%
% Author: R.M.D. Kock, Leiden University

%%
locs = params{1,2};
%pks = params{1,1}; prom = params{1,3}; width = params{1,4};
%pks_AMs = [];

AMs = [];
NAM_tmp = [];
for i=1:length(taps)
    AMs = [AMs locs(locs <= taps(i)+precision_am & locs >= taps(i)-precision_am)];
    NAM_tmp = [NAM_tmp locs(locs <= taps(i)+vicinity & locs >= taps(i)-vicinity)];
end
AMs = unique(AMs);
% AM stuff
s.AMs = AMs;
%s.pks_AMs = pks(ismember(locs,s.AMs));
%s.prom_AMs = prom(ismember(locs,s.AMs));
%s.width_AMs = width(ismember(locs,s.AMs));


% NAM with tap in vicinity
NAM_tmp = unique(NAM_tmp);
s.NAMs_t = NAM_tmp(~ismember(NAM_tmp, s.AMs));
%s.pks_NAMs_t = pks(ismember(locs,s.NAMs_t));
%s.prom_NAMs_t = prom(ismember(locs,s.NAMs_t));
%s.width_NAMs_t = width(ismember(locs,s.NAMs_t));

% NAM without tap in vicinity
s.NAMs = locs(~ismember(locs, s.AMs) & ~ismember(locs, s.NAMs_t));
%s.pks_NAMs = pks(~ismember(locs, s.AMs) & ~ismember(locs, s.NAMs_t));
%s.prom_NAMs = prom(~ismember(locs, s.AMs) & ~ismember(locs, s.NAMs_t));
%s.width_NAMs = width(~ismember(locs, s.AMs) & ~ismember(locs, s.NAMs_t));


end
