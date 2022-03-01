function [all_predictions_read] = read_predictions(participant, path_saved_predictions)
%% Prepare data for training.
% Reads the predictions, of the bs_to_tap models, saved as h5 file,
% for all files from one participant
%
% **Usage:** [all_predictions_read] = read_predictions(participant, path_saved_predictions)
%
% Input(s):
%   - participant : char participant name to be read
%   - path_saved_predictions : char path to the saved predictions
%
% Output(s):
%   - all_predictions_read : cell parsed predictions of all the files for one participant
%         all_predictions_read{file_idx,1} = participant folder name;
%         all_predictions_read{file_idx,2} = integral predictions;
%         all_predictions_read{file_idx,3} = deltas predictions;
%         all_predictions_read{file_idx,4} = optimal threshold intergals;
%         all_predictions_read{file_idx,5} = optimal threshold deltas;
%         all_predictions_read{file_idx,6} = all thresholds intergals for all splits;
%         all_predictions_read{file_idx,7} = all thresholds deltas for all splits;
%         where file_idx is index for every file in the folder
%
% Author: R.M.D. Kock, Leiden University

%%
all_predictions_read = {};

% check if there are any predictions made on participant
info_all_groups = h5info(path_saved_predictions, strcat('/'));
participants_with_bs = {info_all_groups.Groups.Name};
participant_present = cellfun(@(x) contains(x, participant), participants_with_bs);
if isempty(participants_with_bs(participant_present))
    return
end
%% get all files and subwindow paths for participant
info = h5info(path_saved_predictions, strcat('/', participant));
file_names = {info.Datasets.Name};
z = cellfun(@(x) strsplit(x, '_'), file_names, 'UniformOutput', false);
file = unique(cellfun(@(x) strcat(x{1,1},'_',x{1,2}), z, 'UniformOutput', false));
file = file(~ismember(file,{'deltas_optimal','integral_optimal'}));
file_split = unique(cellfun(@(x) strcat(x{1,1},'_',x{1,2},'_',x{1,3}), z, 'UniformOutput', false));
file_split = file_split(~ismember(file_split,{'deltas_optimal_threshold','integral_optimal_threshold'}));
%% read the predictions and concat for same files
for file_idx=1:length(file)
    num_splits = sum(cell2mat(cellfun(@(x) strfind(x, file{1,file_idx}), file_split, 'UniformOutput', false)));
    all_integrals = [];
    all_deltas = [];
    all_thresholds_i = zeros(1,num_splits); 
    all_thresholds_d = zeros(1,num_splits);
    for split_index = 1:num_splits
        group_name_top = strcat('/', participant, '/', file{1,file_idx}, '_', num2str(split_index));
        integrals = h5read(path_saved_predictions, strcat(group_name_top, '_integral_predictions'));
        deltas = h5read(path_saved_predictions, strcat(group_name_top, '_deltas_predictions'));
        optimal_threshold_d = h5read(path_saved_predictions, strcat(group_name_top, '_deltas_optimal_threshold'));
        optimal_threshold_i = h5read(path_saved_predictions, strcat(group_name_top, '_integral_optimal_threshold'));
        all_integrals = [all_integrals  integrals];
        all_deltas = [all_deltas  deltas];
        
        all_thresholds_i(split_index) = optimal_threshold_i;
        all_thresholds_d(split_index) = optimal_threshold_d;
    end
    all_predictions_read{file_idx,1} = file{1,file_idx};
    all_predictions_read{file_idx,2} = all_integrals;
    all_predictions_read{file_idx,3} = all_deltas;
    % if there were multiple file splits (data was more than 10 mins) use
    % the overall F2 score over all the splits as the optimal_threshold 
    if num_splits > 1
        all_predictions_read{file_idx,4} = h5read(path_saved_predictions, strcat('/',participant, '/integral_optimal_threshold_overall'));
        all_predictions_read{file_idx,5} = h5read(path_saved_predictions, strcat('/',participant, '/deltas_optimal_threshold_overall'));
    else
        all_predictions_read{file_idx,4} = optimal_threshold_i;
        all_predictions_read{file_idx,5} = optimal_threshold_d;
    end 
    % keep all the thresholds across splits 
    all_predictions_read{file_idx,6} = all_thresholds_i;
    all_predictions_read{file_idx,7} = all_thresholds_d;
end
end