function [all_data,erp_data,all_bs_to_tap_predictions] = call_func_for_all_participants_eeg(path,save_path,f, options)
%% General function that preprocesses the EEG data and calls a function for all the participants
%
% **Usage:** [all_data] = call_func_for_all_participants_eeg(path,save_path,f, options)
%
%  Input(s):
%   - path = path to raw data
%   - save_path = path to save the results
%   - f = function handle of function to be called
%   - options.start_idx **optional** double = start index of the loop
%   - options.end_idx **optional** double = end index of the loop
%   - options.save_fig **optional** logical = 1 save individual spectograms, 0 does not save
%   - options.event_name_d **optional** cell = delta event(s) to epoch around options are NAMs_d, AMs_d or pt
%   - options.event_name_i **optional** cell = integral event(s) to epoch around options are NAMs_i, AMs_i or pt
%   - options.epoch_window_ms **optional** cell (1,2) = epoch window in ms (e.g. [-1000 500])
%   - options.epoch_window_baseline **optional** cell (1,2) = baseline window in MS (e.g. [-1000 -800])
%   - options.seperate **optional** logical = 0 epoch AMs and NAMs together, 1 epoch AMs and NAMs seperately
%   - options.cycles **optional** double = [1 0.5] 0 for FFT or array for wavelet transform (See newtimef cycles)
%   - options.plot **optional** logical = 1 create diagnostic plots
%
%  Output(s):
%   - all_data = generated data set (see function passed for more info)
%
% Author: R.M.D. Kock

arguments
    path char;
    save_path char;
    f ; % function_handle or cell array of function handles
    options.start_idx (1,1) double = 1;
    options.end_idx (1,1) double = 0;
    options.event_name_d cell = {'NAMs_d', 'AMs_d'}
    options.event_name_i cell = {'NAMs_i','AMs_i'}
    options.artificial_touch logical = 0;
    options.epoch_window_ms (1,2) double = [-2000 2000];
    options.epoch_window_baseline (1,2) double = [-2000 -1500];
    options.seperate logical = 0;
    options.cycles double = [1 0.5];
    options.plot logical = 1;
    options.save_fig logical = 1;
    options.ersp_all_trials logical = 1
    options.type_ancova_mod logical = 1
    options.ancova_type logical = 1
    options.bandpass_upper_range double = 30;
    options.bandpass_lower_range double = 0.5;
    options.R_bounds (1,2) double = [0.8,1];
end
%%
data_folder = dir(path);
participants = {data_folder([data_folder.isdir]).name};
participants = participants(~ismember(participants,{'.','..'}));
if ~(options.end_idx)
    options.end_idx = length(participants);
end
options.save_path = save_path;

all_data = {}; erp_data = {}; all_bs_to_tap_predictions = {};
indx = 1; indx_2 = 1;
for i=options.start_idx:options.end_idx
    participant = participants{1,i}
    files = dir(sprintf('%s/%s', path, participant));
    data_files = {files.name};
    data_files = data_files(~ismember(data_files,{'.','..'}));
    
    if sum(contains(data_files, 'status_2'))
        load(sprintf('%s/%s/status.mat', path, participant));
        load(sprintf('%s/%s/status_2.mat', path, participant));
        
        % Ignore second file for curfew participants
        [eeg_name] = calculate_date_differences(eeg_name);
        selected_files = {};
        idx = 1;
        for h=1:length({eeg_name.EEG})
            % keep the file names of existing set files only
            existing = all_set_files(:,contains(all_set_files(1,:), strcat(eeg_name(h).processed_name, '.set')));
            % Only select files that meet the following conditions:
            % - check if EEG present
            % - check if file has any predictions
            % - approved by participant selection
            % - check if participant is a curfew participant
            % - if so make sure only the non curfew file is selected
            if eeg_name(h).EEG && ~isempty(existing) && existing{2} && existing{3} && (~(eeg_name(h).CurfewExp) || eeg_name(h).datediff == 0)
                selected_files{idx} = eeg_name(h).processed_name;
                idx = idx + 1;
            end
        end
        % Reset these variables
        all_eeg_structs_am = []; all_eeg_structs_nam = [];
        EEG_integrals_am = []; EEG_integrals_nam = [];
        EEG = []; bs_to_tap_predictions = {}; R = 0;
        for selected_file_idx=1:length(selected_files)
            EEG = pop_loadset(sprintf('%s/%s/%s.set', path, participant, selected_files{selected_file_idx}));
            if mod(size(EEG.data,2), EEG.pnts) == 0 && ~(EEG.Attys)
                EEG = gettechnincallycleanEEG(EEG, options.bandpass_upper_range,options.bandpass_lower_range);
                bs_to_tap_predictions{selected_file_idx,1} = participant;
                bs_to_tap_predictions{selected_file_idx,2} = EEG.Aligned.BS_to_tap.BS;
                bs_to_tap_predictions{selected_file_idx,3} = EEG.Aligned.BS_to_tap.deltas;
                bs_to_tap_predictions{selected_file_idx,4} = EEG.Aligned.BS_to_tap.integrals;
                bs_to_tap_predictions{selected_file_idx,5} = EEG.Aligned.BS_to_tap.Phone;
                bs_to_tap_predictions{selected_file_idx,6} = EEG.Aligned.BS_to_tap.threshold_i;
                bs_to_tap_predictions{selected_file_idx,7} = EEG.Aligned.BS_to_tap.threshold_d;
                
                % This is used for spectral data
                if options.seperate
                    if ~(options.artificial_touch)
                        [EEG_integrals_am,~] = pred_events(EEG,{'AMs_d'}, {'AMs_i'},options.epoch_window_ms/1000);
                        [EEG_integrals_nam,~] = pred_events(EEG,{'NAMs_d'}, {'NAMs_i'},options.epoch_window_ms/1000);
                        all_eeg_structs_am = [all_eeg_structs_am EEG_integrals_am];
                        all_eeg_structs_nam = [all_eeg_structs_nam EEG_integrals_nam];
                    else
                        [~, ~,~,EEG_integrals_am] = pred_events(EEG,{''}, {'AMs_AT_i'},options.epoch_window_ms/1000);
                        [~, ~,~,EEG_integrals_nam] = pred_events(EEG,{''}, {'NAMs_AT_i'},options.epoch_window_ms/1000);
                        all_eeg_structs_am = [all_eeg_structs_am EEG_integrals_am];
                        all_eeg_structs_nam = [all_eeg_structs_nam EEG_integrals_nam];
                    end
                else
                    if ~(options.artificial_touch)
                        [EEG_integrals_am,~] = pred_events(EEG,options.event_name_d, options.event_name_i,options.epoch_window_ms/1000);
                        all_eeg_structs_am = [all_eeg_structs_am EEG_integrals_am];
                    else
                        % Note: in this case the am or nam suffix is meaningless
                        [EEG_integrals_am,~] = pred_events(EEG,options.event_name_d, options.event_name_i,options.epoch_window_ms/1000);
                        all_eeg_structs_am = [all_eeg_structs_am EEG_integrals_am];
                    end
                end
            end
        end
        % check if EEG_integrals is not empty because of thresholding and
        % correction
        if ~isempty(bs_to_tap_predictions) && ~isempty(EEG_integrals_am) 
            [s_i] = get_ams_nam(bs_to_tap_predictions);
            [epoched_bs_around_AMs,epoched_bs_around_NAMs] = merge_file_BS_epoched(bs_to_tap_predictions, [-3000 3000],s_i);
            [epoched_bs_around_AMs,epoched_bs_around_NAMs] = interpRW(bs_to_tap_predictions, epoched_bs_around_AMs,epoched_bs_around_NAMs);
            R = corrcoef(median(normalize(epoched_bs_around_AMs{1,1},2),1,'omitnan'),median(normalize(epoched_bs_around_NAMs{1,1},2),1,'omitnan'));
            R = R(2);
        end
        if R > options.R_bounds(1) && ~isempty(bs_to_tap_predictions) && ~isempty(EEG_integrals_am)
            % merge EEG structs
            if length(all_eeg_structs_am)>1 && options.seperate
                EEG_integrals_am = pop_mergeset(all_eeg_structs_am, 1);
                EEG_integrals_nam = pop_mergeset(all_eeg_structs_nam, 1);
            elseif length(all_eeg_structs_am)>1
                EEG_integrals_am = pop_mergeset(all_eeg_structs_am, 1);
            end
            % if there is EEG data call the function
            if length(f) >1
                f1 = f{1}; f2 = f{2};
                if nargout(f1) && ~isempty(EEG_integrals_am)
                    [all_data, indx] = f1(EEG_integrals_am,EEG_integrals_nam, participants{1,i}, indx, all_data, options);
                    if options.type_ancova_mod
                        [erp_data, indx_2] = f2(EEG_integrals_am,EEG_integrals_nam, participants{1,i}, indx_2, erp_data, options);
                    else
                        [all_data, ~] = f2(EEG_integrals_am,EEG_integrals_nam, participants{1,i}, indx, all_data, options);
                    end
                end
            elseif ~isempty(EEG_integrals_am)
%                 try
                    [all_data, indx] = f(EEG_integrals_am,EEG_integrals_nam, participants{1,i}, indx, all_data, options);
                    % TEMP! remove if statement
                    if ~(options.artificial_touch)
                        all_bs_to_tap_predictions{1,i} = bs_to_tap_predictions;
                    end
%                 catch ME
%                     continue
%                 end
            end
        end
    end
end
end
