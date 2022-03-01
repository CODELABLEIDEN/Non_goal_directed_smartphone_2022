function varargout = call_func_for_all_participants(path,save_path,f, options)
%% Calls a function for all the participants (reads the EEG struct of the participant)
%
% **Usage:** [] = call_func_for_all_participants(path,save_path,f, options)
%
%  Input(s):
%   - path = path to raw data
%   - save_path = path to save the results
%   - f = function handle of function to be called
%   - options.start_idx **optional** double = start index of the loop
%   - options.end_idx **optional** double = end index of the loop
%   - options.load_eeg **optional** logical = 1 load the eeg struct, 0 does not load the struct
%
%  Output(s):
%   - outputs from the passed function
%
% Author: R.M.D. Kock

arguments
    path char
    save_path
    f function_handle
    options.start_idx (1,1) double = 1
    options.end_idx (1,1) double = 142
    options.load_eeg logical = 1
    options.predict_MA logical = 0
    options.net = []
    options.align logical = 0
end
%%
EEG = [];
% loop over all the participant folders
data_folder = dir(path);
participants = {data_folder([data_folder.isdir]).name};
participants = participants(~ismember(participants,{'.','..'}));
for i=options.start_idx:options.end_idx
    files = dir(sprintf('%s/%s', path, participants{1,i}));
    data_files = {files.name};
    data_files = data_files(~ismember(data_files,{'.','..'}));
    if options.predict_MA
        participant_upper = sprintf('%s_%d', participants{1,i});
        save_path_lower = sprintf('%s/%s', save_path, participant_upper);
        mkdir(save_path_lower)
    end
    idx = 0;
    % loop over all the files inside the folders
    for inner_loop_idx=1:size(data_files,2)
        % only load the set files
        if contains(data_files{1,inner_loop_idx}, 'set')
            if (options.load_eeg)
                disp('loading set file')
                EEG = pop_loadset(data_files{1,inner_loop_idx});
            end
            participant = sprintf('%s_%d', participants{1,i}, inner_loop_idx);
            if nargout(f) 
                if isfield(EEG.Aligned, 'BS_to_tap')
                    idx = idx + 1;
                    f(EEG, participants{1,i}, idx);
                end
            else
                if options.predict_MA && ~isempty(options.net)
                    [EEG, BS] = f(EEG, inner_loop_idx, participant, save_path, options);
                    if options.align && ~isempty(EEG.Aligned.BSnet)
                        [EEG, simple] = decision_tree_alignment(EEG, BS,options.create_alignment_plot, options.participant_selection);
                        if simple
                            disp('Alignment successfull, data in EEG.Aligned.Phone.Model')
                        else
                            warning('Data was not aligned')
                        end
                    elseif  options.align & isempty(EEG.Aligned.BSnet)
                        warning('Data was not aligned')
                    end
                    pop_saveset(EEG,data_files{1,inner_loop_idx}, save_path_lower);
                else
                    f(EEG, inner_loop_idx, participant, save_path);
                end
            end
        end
    end
end
