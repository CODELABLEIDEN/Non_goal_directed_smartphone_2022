function main_t_tests(path, options)
%% LIMO t_tests for ERP and ERSP data for AMs, NAMs, and paired t_tests
%
% **Usage:** 
%   - main_t_tests(path)
%   - main_t_tests(..., 'trials', [50, 100])
%   - main_t_tests(..., 'erp_all_data', erp_all_data, 'ersp_all_data', ersp_all_data)
%
%  Input(s):
%   - path = path to checkpoint files with erp and ersp data
%   - options.trials **optional** double = [50] array with the minimum number of trials (example: [50, 100])
%   - options.erp_all_data = erp data generated with generate_erp_data (see required structure)
%   - options.ersp_all_data = erp data generated with generate_spectral_data (see required structure)
%
%  Output(s):
%   - saves all the results from LIMO t_tests for each test in folders
%
% Requires:
%   - preprocess_erp_data.m 
%   - preprocess_ersp_data.m
%   - run_t_tests_and_clustering.m
%
% Author: R.M.D. Kock, Leiden University

arguments
    path char;
    options.trials = [50];
    options.erp_all_data = [];
    options.ersp_all_data = [];
end
%% Load checkpoint files
if isempty(options.erp_all_data)
    % load erp files
    [options.erp_all_data] = load_EEG_checkpoints(path, 'erp', 'erp_data', 'save_results', 0);
end
if isempty(options.ersp_all_data)
    [options.ersp_all_data] = load_EEG_checkpoints(path, 'ersp', 'all_data', 'save_results', 0);
end
%% run t-tests
for i=1:length(options.trials)
    %% ERP
    paired = 0;
    tf = 0;
    [erp_data, ams, nams] = preprocess_erp_data(options.erp_all_data, paired, options.trials(i));
    % one sample ttest for ERP around attributable movements
    [LIMO_path_am] = run_t_tests_and_clustering(sprintf('erp_am_%d',options.trials(i)), paired, tf, ams);
    % one sample ttest for ERP around non attributable movements
    [LIMO_path_nam] = run_t_tests_and_clustering(sprintf('erp_nam_%d',options.trials(i)), paired, tf, nams);
    
    %% paired samples ttest for ERP around attributable and non attributable movements
    paired = 1;
    [erp_data, ams, nams] = preprocess_erp_data(options.erp_all_data, paired,options.trials(i));
    [LIMO_path_nam] = run_t_tests_and_clustering(sprintf('erp_paired_%d',options.trials(i)), paired, tf, ams, nams);
    
    %% ERSP
    paired = 0;
    tf = 1;
    [all_data, reshaped_p_ams, reshaped_p_nams] = preprocess_ersp_data(options.ersp_all_data, paired, options.trials(i));
    % one sample ttest for ERSP around attributable movements
    [LIMO_path_am] = run_t_tests_and_clustering(sprintf('ersp_am_%d',options.trials(i)), paired, tf, reshaped_p_ams);
    % one sample ttest for ERSP around non attributable movements
    [LIMO_path_nam] = run_t_tests_and_clustering(sprintf('ersp_nam_%d',options.trials(i)), paired, tf, reshaped_p_nams);
    
    %% paired samples ttest for ERSP around attributable and non attributable movements
    paired = 1;
    [all_data, reshaped_p_ams, reshaped_p_nams] = preprocess_ersp_data(options.ersp_all_data, paired, options.trials(i));
    [LIMO_path_nam] = run_t_tests_and_clustering(sprintf('ersp_paired_%d',options.trials(i)), paired, tf, reshaped_p_ams, reshaped_p_nams);
end