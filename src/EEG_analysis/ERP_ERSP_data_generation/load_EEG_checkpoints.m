function [load_data] = load_EEG_checkpoints(path, load_str, data_name, options)
%% load erp and or ersp checkpoints
%
% **Usage:**
%   -  [erp_all_data, ersp_all_data] = load_EEG_checkpoints(path, load_str, data_name,)
%   -  [erp_all_data, ersp_all_data] = load_EEG_checkpoints(..., 'save_results', 0)
%   -  [erp_all_data, ersp_all_data] = load_EEG_checkpoints(..., 'save_path', path)
%
%  Input(s):
%   - path = path to checkpoint files with erp and ersp data
%   - load_str = unique string in checkpoint name
%   - options.save_results **optional** logical = 1 -- 0 not to save the results
%   - options.save_path **optional** char = path -- save path
%
%  Output(s):
%   - loaded_data = erp data from all checkpoints
%
%
% Author: R.M.D. Kock, Leiden University

arguments
    path char;
    load_str char;
    data_name char;
    options.save_results logical = 1;
    options.save_path char = path;
    options.load logical =1;
end
%%
load_data = [];
folder_contents = dir(path);
files = {folder_contents.name};
%% load erp checkpoints
all_files = files(cellfun(@(x) contains(x, load_str),files));
load_data = {};
for i=1:length(all_files)
    tmp = load(all_files{i});
    if strcmp(data_name, 'bs_to_tap') || strcmp(data_name, 'trialAT')
        tmp = tmp.(data_name)(~cellfun(@isempty ,tmp.(data_name)));
        load_data = cat(1,load_data,tmp{:});
    else
        load_data = cat(1,load_data,tmp.(data_name));
    end
end
if options.save_results
    options.save(sprintf('%s/%s_all_data.mat', options.save_path,load_str), 'load_data')
end
end