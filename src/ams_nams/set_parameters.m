function [EEG] = set_parameters(EEG, feature, params, all_eventtypes)
%% Extract the features used for GLM
% **Usage:** [EEG] = set_parameters(EEG, feature, params, all_eventtypes)
%
% Input(s):
%   - EEG = EEG struct
%   - feature = cell with the feature name (either delta and integral)
%   - params = struct with results from findpeaks, peak local maxima,
%   width, promincence and location
%   - all_eventtypes = name of events to calculate the parameters from (as
%   set by add_events() all options are AMs (AMs_d AMs_i) and NAMs (NAMs_d NAMs_i)
%   from both integral and delta feature and phone touches (pt)
%
% Output(s):
%   - EEG = EEG struct with parameters in EEG.epoch
%
% Requires:
%   - find_nearest_distances.m
%
% Author: R.M.D. Kock, Leiden University

%%
% uncomment when used as script
% EEG_raw = EEG; EEG = EEG_epoched_integrals; feature = features{1,2}; params = params_i; all_eventtypes = event_name_i;

pks = params{1,1}; locs = params{1,2}; p = params{1,3}; w = params{1,4};
% set parameter for each event type
for i=1:length(all_eventtypes)
    if ~isempty(EEG.epoch)
        eventtype_epoched_name = all_eventtypes{i}
        %% Get event latencies
        urevents = cellfun(@(eventlatency,ureventlatency, event_type) cell2mat(cellfun(@(x,y,type) y(x==0 & strcmp(eventtype_epoched_name,type)), eventlatency, ureventlatency,event_type, 'UniformOutput', false)), {EEG.epoch.eventlatency}, {EEG.epoch.eventurevent},{EEG.epoch.eventtype}, 'UniformOutput', false);
        eventtypes = cellfun(@(eventlatency,ureventlatency, event_type) char(cellfun(@(x,y,type) type(x==0 & strcmp(eventtype_epoched_name,type)), eventlatency, ureventlatency,event_type, 'UniformOutput', false)), {EEG.epoch.eventlatency}, {EEG.epoch.eventurevent},{EEG.epoch.eventtype}, 'UniformOutput', false);
        encoded_eventtypes = ~cellfun(@isempty, eventtypes);
        urevents_from_events = EEG.urevent(cell2mat(urevents));
        latencies = [urevents_from_events.latency];  
        indexes_by_event = find(~cellfun(@isempty,urevents));
        %% Categorical variables
        cat = num2cell([encoded_eventtypes]);
        [EEG.epoch.(eventtype_epoched_name)] = cat{:};
        %% Prediction amplitude
        pks = num2cell(EEG.Aligned.BS_to_tap.(feature)(latencies));
        [EEG.epoch(indexes_by_event).pks] = pks{:};
        %%
        bs_vals = [];
        for i = 1:length(latencies)
            j = EEG.Aligned.BS_to_tap.BS(latencies(i)-250:latencies(i)+250);
            bs_vals = [bs_vals sum(abs(j))];
        end
        bs_val = num2cell(bs_vals);
        [EEG.epoch(indexes_by_event).bs] = bs_val{:};
        %% Peak prominance and width
        if ~strcmp(eventtype_epoched_name,'pt')
            if length(all_eventtypes) == 1
                prom = num2cell(p(ismember(locs, latencies)));
                width = num2cell(w(ismember(locs, latencies)));
                [EEG.epoch(indexes_by_event).prom] = prom{:};
                [EEG.epoch(indexes_by_event).width] = width{:};
            end
        end
        %% Distance to nearest taps (before and after event)
        taps = find(EEG.Aligned.BS_to_tap.Phone == 1);
        [distance_maxs, distance_mins, maxs, mins] = find_nearest_distances(taps,latencies, taps);
        distance_maxs = num2cell(distance_maxs);
        distance_mins = num2cell(distance_mins);
        [EEG.epoch(indexes_by_event).distance_tap_after_event] = distance_maxs{:};
        [EEG.epoch(indexes_by_event).distance_tap_before_event] = distance_mins{:};
        max_nans = isnan(maxs);
        pks_tmp_after = EEG.Aligned.BS_to_tap.(feature)(maxs(~max_nans));
        pks_after = nan(size(maxs));
        pks_after(~max_nans) = pks_tmp_after;
        pks_after_f = num2cell(pks_after);
        
        min_nans = isnan(mins);
        pks_tmp_before = EEG.Aligned.BS_to_tap.(feature)(mins(~min_nans));
        pks_before = nan(size(mins));
        pks_before(~min_nans) = pks_tmp_before;
        pks_before_f = num2cell(pks_before);
        [EEG.epoch(indexes_by_event).pks_after_tap] = pks_after_f{:};
        [EEG.epoch(indexes_by_event).pks_before_tap] = pks_before_f{:};
        
        %% Distance to nearest prediction (before and after event)
        [distance_maxs_pred, distance_mins_pred, maxs_pred, mins_pred,types] = find_nearest_distances(locs,latencies,taps);
        distance_maxs_pred = num2cell(distance_maxs_pred);
        distance_mins_pred = num2cell(distance_mins_pred);
        [EEG.epoch(indexes_by_event).distance_pred_after_event] = distance_maxs_pred{:};
        [EEG.epoch(indexes_by_event).distance_pred_before_event] = distance_mins_pred{:};
        max_nans_pred = isnan(maxs_pred);
        pks_tmp_after_pred = EEG.Aligned.BS_to_tap.(feature)(maxs_pred(~max_nans_pred));
        pks_after_pred = nan(size(maxs_pred));
        pks_after_pred(~max_nans_pred) = pks_tmp_after_pred;
        pks_after_pred_f = num2cell(pks_after_pred);
        [EEG.epoch(indexes_by_event).pks_pred_after] = pks_after_pred_f{:};
        
        min_nans_pred = isnan(mins_pred);
        pks_tmp_before_pred = EEG.Aligned.BS_to_tap.(feature)(mins_pred(~min_nans_pred));
        pks_pred_before_pred = nan(size(mins_pred));
        pks_pred_before_pred(~min_nans_pred) = pks_tmp_before_pred;
        pks_pred_before_pred_f = num2cell(pks_before);
        [EEG.epoch(indexes_by_event).pks_pred_before] = pks_pred_before_pred_f{:};
        
        [EEG.epoch(indexes_by_event).types_before_event] = types{1,:};
        [EEG.epoch(indexes_by_event).types_after_event] = types{2,:};
        % pred_distance_maxs = num2cell(EEG.Aligned.BS_to_tap.deltas(maxs));
        % pred_distance_mins = num2cell(EEG.Aligned.BS_to_tap.deltas(mins));
        % [EEG.epoch.pred_distance_tap_after_event] = pred_distance_maxs{:};
        % [EEG.epoch.pred_distance_tap_before_event] = pred_distance_mins{:};
    end
end
end