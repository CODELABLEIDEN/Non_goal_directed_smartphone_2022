function [erp_data, indx] = generate_erp_data(EEG_integrals_am, EEG_integrals_nam,participant, indx, erp_data, options)
%% Calculates ERP per participant
%
% **Usage:** [all_data] = generate_erp_data(EEG1_i, EEG1_d,participant, indx, all_data)
%
% Input(s):
%   - EEG1_i = EEG struct with epoched integral data
%   - EEG1_d = EEG struct with epoched deltas data
%   - participant = participant
%   - indx = index to place the participant data in cell
%   - erp_data = cell with the epoched EEG data of other participants
%
% Output(s):
%   - erp_data = cell placeholder cell with the epoched predictions of one participant
%       - erp_data{indx,1} = participant name
%       - erp_data{indx,2} = trimmed ERP for attributable movements (AM)
%       - erp_data{indx,3} = trimmed ERP for non attributable movements (NAM)
%       - erp_data{indx,4} = (mean) ERP for attributable movements (AM)
%       - erp_data{indx,5} = (mean) ERP for non attributable movements (NAM)
%       - erp_data{indx,6} = number of trials for attributable movements (AM)
%       - erp_data{indx,7} = number of trials for non attributable movements (NAM)
%
% Author: R.M.D. Kock, Leiden University

%% cleaning
trials_nam = 51; trimed_eeg_nam = []; mean_eeg_nam = []; nam_epoch = [];
% baseline correction
EEG_integrals_am = pop_rmbase(EEG_integrals_am, options.epoch_window_baseline);
% Reject epochs based on thresholding
electrodes_to_reject = [1:62];
voltage_lower_threshold = -80; % In mV
voltage_upper_threshold = 80;
start_time = options.epoch_window_ms(1)/1000;
end_time = options.epoch_window_ms(2)/1000;
do_superpose = 0;
do_reject = 1;
try
    EEG_integrals_am = pop_eegthresh(EEG_integrals_am, 1, electrodes_to_reject, voltage_lower_threshold, voltage_upper_threshold, start_time, end_time, do_superpose, do_reject);
catch ME
    return
end

if ~isempty(EEG_integrals_nam)
    EEG_integrals_nam = pop_rmbase(EEG_integrals_nam, options.epoch_window_baseline);
    try
        EEG_integrals_nam = pop_eegthresh(EEG_integrals_nam, 1, electrodes_to_reject, voltage_lower_threshold, voltage_upper_threshold, start_time, end_time, do_superpose, do_reject);
    catch ME
        return
    end
    trials_nam = size(EEG_integrals_nam.epoch,2);
end

% get the number of trials for each event
trials_am = size(EEG_integrals_am.epoch,2);


% only select participants with atleast 50 of each event
if (trials_am > 50) && (trials_nam > 50)
    trimed_eeg_am = trimmean(EEG_integrals_am.data(:,:,:),20,3);
    if ~isempty(EEG_integrals_nam)
        trimed_eeg_nam = trimmean(EEG_integrals_nam.data(:,:,:),20,3);
        mean_eeg_nam = [mean(EEG_integrals_nam.data(:,:,:),3,'omitnan')];
        nam_epoch = EEG_integrals_nam.epoch;
    end
    erp_data{indx, 1} = participant;
    erp_data{indx, 2} = [trimed_eeg_am];
    erp_data{indx, 3} = [trimed_eeg_nam];
    erp_data{indx, 4} = [mean(EEG_integrals_am.data(:,:,:),3,'omitnan')];
    erp_data{indx, 5} = mean_eeg_nam;
    erp_data{indx, 6} = trials_am;
    erp_data{indx, 7} = trials_nam;
    erp_data{indx, 8} = EEG_integrals_am.epoch;
    erp_data{indx, 9} = nam_epoch;
    indx = indx + 1;
end
end