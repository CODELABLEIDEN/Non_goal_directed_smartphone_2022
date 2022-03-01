function create_hdf5(EEG, inner_loop_idx, participant, save_path)
%% Create hdf file with data for model training
%
% **Usage:** create_hdf(EEG, inner_loop_idx, participant, save_path)
%
% Input(s):
%   - EEG = EEG struct
%   - inner_loop_idx = index in which to add the data in the h5 file
%   - participant = participant folder name and file number (E.g. AGO3_2)
%   - save_path = path to save the file with .h5 extention.
%     Example: 'data/bs_to_tap_train_data/feature_files.h5'
%
% Output(s):
%   - generates a h5 file at the save_path location with the training data
%
% Requires:
%   - prepare_features.m
%
% Author: R.M.D. Kock, Leiden University

[deltas] = prepare_features(EEG, 1);
[integrals, Phone] = prepare_features(EEG, 0);
split_p = split(participant, '_');
participant_top = split_p{1,1};

for window=1:length(Phone)
    % Check if there is any phone data
    % Check if there is any BS data
    % Check if the BS data is not only NANs
    if ~isempty(deltas{window,1}) && ~isempty(Phone{window,1}) && ~(sum(isnan(deltas{window,1})==1) == length(deltas{window,1}))
        h5create(save_path,sprintf('/%s/%s_%d_integrals',participant_top,participant,window),(size(integrals{window,1}.')));
        h5write(save_path,sprintf('/%s/%s_%d_integrals',participant_top,participant,window),integrals{window,1}.');
        h5create(save_path,sprintf('/%s/%s_%d_deltas',participant_top,participant,window),(size(deltas{window,1}.')));
        h5write(save_path,sprintf('/%s/%s_%d_deltas',participant_top,participant,window),deltas{window,1}.');
        h5create(save_path,sprintf('/%s/%s_%d_phone',participant_top,participant,window),(size(Phone{window,1}.')));
        h5write(save_path,sprintf('/%s/%s_%d_phone',participant_top,participant,window),Phone{window,1}.');
    end
end
end
