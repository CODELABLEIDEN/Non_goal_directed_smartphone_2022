function save_predictions(~, ~, participant, paths)
%% Save the predictions in EEG struct format
% Save the predictions for one participant in EEG struct format
%
% **Usage:** save_predictions([],[],participant, paths)
%
% Input(s):
%   - participant = string participant name to be read
%   - paths = cell array with
%       - raw_data_path : path to EEG struct with alignment model
%       - save_path_upper : path to save new EEG struct with alignment and
%           bs_to_tap model predictions
%       - path_saved_predictions : string path to the saved predictions
%
% Output(s):
%   - Saves a set file with these fields added
%         EEG.Aligned.BS_to_tap.Phone : phone data
%         EEG.Aligned.BS_to_tap.integrals : integral model predictions
%         EEG.Aligned.BS_to_tap.deltas : delta model predictions
%         EEG.Aligned.BS_to_tap.BS : preprocessed bendesensor data
%         EEG.Aligned.BS_to_tap.threshold_i : optimal threshold for integral
%         EEG.Aligned.BS_to_tap.threshold_d : optimal threshold for deltas
%         EEG.Aligned.BS_to_tap.all_threshold_i : optimal thresholds for all file splits integral
%         EEG.Aligned.BS_to_tap.all_threshold_d : optimal thresholds for all file splits deltas
%
% Requires:
%   - read_predictions.m
%   - get_phone_data.m
%   - getcleanedbsdata.m
%   - decision_tree_alignment.m
%   - remove_inactive_bs.m
%
% Author: R.M.D. Kock, Leiden University

%%
raw_data_path = paths{1,1}; save_path_upper = paths{1,2}; path_saved_predictions = paths{1,3};
participant_split = split(participant, '_');
participant = participant_split{1,1};

save_path_lower = sprintf('%s/%s', save_path_upper, participant);
% get all files for participant
files = dir(sprintf('%s/%s', raw_data_path, participant));
data_files = {files.name};
data_files = data_files(~ismember(data_files,{'.','..'}));
EEG = [];
mkdir(save_path_lower)

% load status file
load(sprintf('%s/%s/status.mat', raw_data_path, participant));
% for all .set files, set BS_to_tap to 0
all_set_files = data_files(cellfun(@(x) contains(x,'.set'), data_files));
all_set_files(2,:) = num2cell(0);
all_set_files(3,:) = num2cell(0);

% check if there are any .set files for participant
if sum(cellfun(@(x) contains(x,'.set'), data_files))>0
    [all_predictions_read] = read_predictions(participant, path_saved_predictions);

    % loop over each .set file that was predicted on
    for i=1:size(all_predictions_read,1)
        % get file number
        split_cells = split(all_predictions_read{i,1}, '_');
        index = str2num(split_cells{2,1});

        % load eeg struct
        filename = data_files{1,index};
        EEG = pop_loadset(filename);
        % set status of BS_to_tap to 1
        all_set_files(2,cellfun(@(x) contains(x,filename), all_set_files(1,:))) = {1};
        %% Phone data
        % align phone data, get phone data, remove inactive sequences, upsample
        BS = getcleanedbsdata(EEG.Aligned.BS.Data(:,1),EEG.srate,[1 10]);
        [EEG, simple]= decision_tree_alignment(EEG, BS, 0,1);
        all_set_files(3,cellfun(@(x) contains(x,filename), all_set_files(1,:))) = {simple};
        % Check if alignment was successful
        if simple
            [Phone, Transitions, idx] = get_phone_data(EEG, 2);
            [Phone_reduced, BS_features_reduced, indices] = remove_inactive_bs(Phone, BS, 600000);
            phone_up = Phone;

            % Delta model predictions
            pred_deltas = all_predictions_read{i,2};
            pred_up_deltas = interp(pred_deltas,EEG.srate/100);

            % Integrals model predictions
            pred_integrals = all_predictions_read{i,3};
            pred_up_integrals = interp(pred_integrals,EEG.srate/100);
            
            % Due to downsampling then interpolation depending on original data length 
            % the data size may vary where the interpolated data has more
            % values than the original data. Remove those extra values.
            if length(pred_up_integrals) > length(BS_features_reduced) 
               pred_up_integrals = pred_up_integrals(1:length(BS_features_reduced));
               pred_up_deltas = pred_up_deltas(1:length(BS_features_reduced));
            elseif length(pred_up_integrals) < length(BS_features_reduced) & isempty(indices)
               length(pred_up_integrals)
               length(BS)
               error('bs and phone unequal sizes')
            end
            
            threshold_i = all_predictions_read{i,4};
            threshold_d = all_predictions_read{i,5};
            all_threshold_i = all_predictions_read{i,6};
            all_threshold_d = all_predictions_read{i,7};
            % plot predictions for one participant
            % plot_events(participant, BS_features_reduced, phone_up, pred_up_deltas, pred_up_integrals,threshold_d,threshold_i);
            
            % insert the sequences of no activity that were discarded
            % during training and prediction
            if indices & length(pred_up_integrals) == size(Phone_reduced,2)
                % get start and end indices that were excluded
                end_idx_excluded = [indices(diff(indices)>1) indices(end)];
                start_idx_excluded = [indices(diff([0 indices(1:end-1)])>1)];
                start = 1;
                full_size_deltas = zeros(size(BS));
                full_size_integrals = zeros(size(BS));
                full_size_phone = zeros(size(Phone));
                included = [];
                processed_data_start = 1;
                start = 1;
                % for every excluded sequence insert the non excluded
                % sequence in an array of raw data length
                
                for s=1:length(end_idx_excluded)
                    included = [start:start_idx_excluded(s)-1];
                    full_size_deltas(included) = pred_up_deltas(processed_data_start:processed_data_start+length(included)-1);
                    full_size_integrals(included) = pred_up_integrals(processed_data_start:processed_data_start+length(included)-1);
                    full_size_phone(included) = phone_up(processed_data_start:processed_data_start+length(included)-1);
                    
                    start = end_idx_excluded(s)+1;
                    processed_data_start  = processed_data_start+length(included);
                end
                
                included = [start:length(BS)];
                full_size_deltas(included) = pred_up_deltas(processed_data_start:processed_data_start+length(included)-1);
                full_size_integrals(included) = pred_up_integrals(processed_data_start:processed_data_start+length(included)-1);
                full_size_phone(included) = phone_up(processed_data_start:processed_data_start+length(included)-1);
            elseif indices & ~(length(pred_up_integrals) == size(Phone_reduced,2))
                error('bs and phone unequal sizes and inactive')
            % if no sequences were excluded then no changes need to be done
            else
                full_size_deltas = pred_up_deltas;
                full_size_integrals = pred_up_integrals;
                full_size_phone = phone_up;
            end
            
            % remove sequences of data with no BS activity this was only
            % the case for RW participants
            if contains(participant, 'RW')
                indices = logical([BS(1) diff(BS)==0]);
                full_size_integrals(indices) = deal(0);
                full_size_deltas(indices) = deal(0);
            end
            % save in EEG struct
            EEG.Aligned.BS_to_tap.Phone = Phone;
            EEG.Aligned.BS_to_tap.integrals = full_size_integrals;
            EEG.Aligned.BS_to_tap.deltas = full_size_deltas;
            EEG.Aligned.BS_to_tap.BS = BS;
            EEG.Aligned.BS_to_tap.threshold_i = threshold_i;
            EEG.Aligned.BS_to_tap.threshold_d = threshold_d;
            EEG.Aligned.BS_to_tap.all_threshold_i = all_threshold_i;
            EEG.Aligned.BS_to_tap.all_threshold_d = all_threshold_d;
        end
        pop_saveset(EEG, filename, save_path_lower)
    end
    % read and save the other files with no predictions
    other_files = all_set_files(1,[all_set_files{2,:}] == 0);
    if length(other_files) > 0
        for j=1:length(other_files)
            EEG = pop_loadset(other_files{1,j});
            pop_saveset(EEG, other_files{1,j}, save_path_lower)
        end
    end
    save(sprintf('%s/status.mat', save_path_lower), 'eeg_name')
    save(sprintf('%s/status_2.mat', save_path_lower), 'all_set_files')
else
    % if there is no .set file save the status file in folder
    save(sprintf('%s/status.mat', save_path_lower), 'eeg_name')
end
end
