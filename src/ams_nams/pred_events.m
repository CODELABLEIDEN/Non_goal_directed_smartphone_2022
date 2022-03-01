function [EEG_integrals, EEG_deltas,indices_integrals,EEG_epoched_AT] = pred_events(EEG, event_name_d, event_name_i, epoch_window)
%% Get EEG in right format; epoched with all GLM parameters
%
% **Usage:** [EEG_integrals, EEG_deltas,indices_integrals] = pred_events(EEG, event_name_d, event_name_i,epoch_window)
%
% Input(s):
%   - EEG = EEG struct
%   - event_name_d: name of events derived from delta features to calculate
%     the parameters from (as set by add_events() all options are AMs_d, NAMs_d and pt)
%   - event_name_i: name of events derived from delta features to calculate
%     the parameters from (as set by add_events() all options are AMs_i, NAMs_i and pt)
%   - epoch_window: epoch window for pop_epoch
%
% Output(s):
%   - EEG_integrals =  processed EEG struct with parameters from integral predictions
%   - EEG_deltas =  processed EEG struct with parameters from delta predictions
%   - indices_integrals = The indices of all integral events
%
% Requires:
%   - find_ams_n_nams.m
%   - add_events.m
%   - set_parameters.m
%
% Author: R.M.D. Kock, Leiden University

EEG_deltas = []; EEG_integrals =[]; EEG_epoched_AT =[];
indices_integrals = [];
%% find predicted events

% select threshold where best F2 score
% any prediction smaller than this threshold is ignored
threshold_d = EEG.Aligned.BS_to_tap.threshold_d;
threshold_i = EEG.Aligned.BS_to_tap.threshold_i;
[pks_d, locs_d, w_d, p_d] = findpeaks(EEG.Aligned.BS_to_tap.deltas, 'MinPeakWidth', 5, 'MinPeakHeight', threshold_d, 'Annotate', 'extents');
[pks_i, locs_i, w_i, p_i] = findpeaks(EEG.Aligned.BS_to_tap.integrals, 'MinPeakWidth', 5, 'MinPeakHeight', threshold_i, 'Annotate', 'extents');

%% Distinguish NAMs from AMs
precision_am = 100;
vicinity = 1000;
taps= [find(EEG.Aligned.BS_to_tap.Phone == 1)];
params_d = {pks_d, locs_d, w_d, p_d};
[s_d] = find_ams_n_nams(taps, params_d, precision_am, vicinity);
params_i = {pks_i, locs_i, w_i, p_i};
[s_i] = find_ams_n_nams(taps, params_i, precision_am, vicinity);
%% artificial touches analysis
precision = 500;
type = '33';
[AMs_AT, NAMs_AT] = find_AM_NAM_AT(EEG, type, s_i,precision);
%% add events to structs
% real taps
num_taps = size(find(EEG.Aligned.BS_to_tap.Phone == 1),2);
[EEG] = add_events(EEG,[find(EEG.Aligned.BS_to_tap.Phone == 1)],num_taps,'pt');
% predictions
[EEG] = add_events(EEG,s_d.AMs,length(s_d.AMs),'AMs_d');
[EEG] = add_events(EEG,s_d.NAMs,length(s_d.NAMs),'NAMs_d');
% [EEG] = add_events(EEG,s_d.NAMs_t,length(s_d.NAMs_t),'NAMs_t_d');
[EEG] = add_events(EEG,s_i.AMs,length(s_i.AMs),'AMs_i');
[EEG] = add_events(EEG,s_i.NAMs,length(s_i.NAMs),'NAMs_i');
% [EEG] = add_events(EEG,s_i.NAMs_t,length(s_i.NAMs_t),'NAMs_t_i');
% EEG_tmp2 = EEG;
if (length(AMs_AT) && length(NAMs_AT))
    [EEG] = add_events(EEG,AMs_AT,length(AMs_AT),'AMs_AT_i');
    [EEG] = add_events(EEG,NAMs_AT,length(NAMs_AT),'NAMs_AT_i');
end
%% epoch data
% event_name_d = {'AMs_d', 'pt', 'NAMs_d'};
% event_name_i = {'AMs_i', 'pt', 'NAMs_i'};
features = {'deltas', 'integrals'};

if (length(s_d.AMs) && sum(strcmp('AMs_d', event_name_d))) || (length(s_d.NAMs) && sum(strcmp('NAMs_d', event_name_d)))
    [EEG_epoched_deltas, indices_deltas] = pop_epoch(EEG, event_name_d,epoch_window);
    [EEG_deltas] = set_parameters(EEG_epoched_deltas, features{1,1}, params_d, event_name_d);
end
if (length(s_i.AMs) && sum(strcmp('AMs_i', event_name_i))) || (length(s_i.NAMs) && sum(strcmp('NAMs_i', event_name_i)))
    [EEG_epoched_integrals, indices_integrals] = pop_epoch(EEG, event_name_i,epoch_window);
    [EEG_integrals] = set_parameters(EEG_epoched_integrals, features{1,2}, params_i, event_name_i);
end
if (length(AMs_AT) && length(NAMs_AT)) && (sum(strcmp('AMs_AT_i', event_name_i)) || sum(strcmp('NAMs_AT_i', event_name_i)))
    [EEG_epoched_AT, indices_AT] = pop_epoch(EEG, event_name_i,epoch_window);
end

if (num_taps) && sum(strcmp('pt', event_name_i))
    [EEG_integrals, ~] = pop_epoch(EEG, event_name_i,epoch_window);
end
end
