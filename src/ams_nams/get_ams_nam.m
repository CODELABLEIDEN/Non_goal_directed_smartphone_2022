function [s_i,s_d,taps] = get_ams_nam(bs_to_tap_predictions)
%% Get ams, nams and tap locations for all participants
%
% **Usage:** [s_i,s_d,taps] = get_ams_nam(bs_to_tap_predictions)
%
% Input(s):
%   - bs_to_tap_predictions = cell placeholder cell with the bs_to_tap data of all participants
%
% Output(s):
%   - s_i = struct with ams, nams idexes for integrals
%   - s_d = struct with ams, nams idexes for deltas
%   - taps = location of smartphone taps
%
% Requires:
%   find_ams_n_nams.m
%
% Author: R.M.D. Kock

%%
[pks_d, locs_d, w_d, p_d] = cellfun(@(deltas,thres) findpeaks(deltas, 'MinPeakWidth', 5, 'MinPeakHeight', thres, 'Annotate', 'extents'), bs_to_tap_predictions(:,3),bs_to_tap_predictions(:,7),'UniformOutput',false);
[pks_i, locs_i, w_i, p_i] = cellfun(@(integrals,thres) findpeaks(integrals, 'MinPeakWidth', 5, 'MinPeakHeight', thres, 'Annotate', 'extents'), bs_to_tap_predictions(:,4),bs_to_tap_predictions(:,6),'UniformOutput',false);

precision_am = 100;
vicinity = 1000;
taps = cellfun(@(phone) find(phone == 1), bs_to_tap_predictions(:,5) ,'UniformOutput',false);
[s_i] = cellfun(@(tap,pks, locs, w, p) find_ams_n_nams(tap, {pks, locs, w, p}, precision_am, vicinity), taps, pks_i, locs_i, w_i, p_i ,'UniformOutput',false);
[s_d] = cellfun(@(tap,pks, locs, w, p) find_ams_n_nams(tap, {pks, locs, w, p}, precision_am, vicinity), taps, pks_d, locs_d, w_d, p_d ,'UniformOutput',false);
end
