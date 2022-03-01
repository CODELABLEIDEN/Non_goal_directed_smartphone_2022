function [processed_BS, processed_phone, BS] = prepare_features(EEG, feature)
%% Prepare data for training. 
% Does the following steps: pre-process BS, align using decision tree, 
% extract features from BS, extract idle sequences from both
% BS and Phone taps, normalize BS, change the sequence precision of Phone
% taps, seperate sequences into multiple 10 mins windows
%
% **Usage:** [processed_BS, processed_phone, BS] = prepare_features(EEG, feature)
%
% Input(s):
%   - EEG : EEG data struct
%   - feature : Bool 0 = integrals, 1 = deltas
%
% Output(s):
%   - processed_BS : processed BS features
%   - processed_phone : processed phone data
%   - BS : processed bensensor data
%
% Requires:
%   - getcleanedbsdata.m (in Utils)
%   - remove_inactive_bs.m (in Utils)
%   - get_phone_data.m (in Utils)
%   - decision_tree_alignment.m (in Alignment)
%   - delta_mod.m
%   - delta_sigma_mod.m
%   - change_sequence_precision.m
%   - seperate_sequences.m
%
% Author: R.M.D. Kock, Leiden University

%%
processed_BS = {};
processed_phone = {};

if isfield(EEG.Aligned.BS, 'Data') && isfield(EEG.Aligned.BS, 'Model')
    bandpass_upper_range = 10;
    if ~isempty(EEG.Aligned.BS.Data(:,1))
        % preprocess BS data
        BS = getcleanedbsdata(EEG.Aligned.BS.Data(:,1),EEG.srate,[1 bandpass_upper_range]);
        % Align data, run decision tree code
        [EEG, simple]= decision_tree_alignment(EEG, BS, 0,1);
        if (simple == 0)
            return
        end

        % get features from BS data
        if (feature)
            [BS_features] = delta_mod(BS);
        else
            [BS_features] = delta_sigma_mod(BS);
        end

        % get aligned phone data
        [Phone, Transitions, idx] = get_phone_data(EEG, 2);

        % remove long sequences of BS data where there was no taps
        % sequence length around 10 mins
        [Phone_reduced, BS_features_reduced] = remove_inactive_bs(Phone, BS_features, 600000);

        % add extra taps
        [decreased_precision_phone] = change_sequence_precision(Phone_reduced, 30);

        % normalize BS
        normalized_BS = normalize(BS_features_reduced);

        % split data
        split_sequence_length = 600000;
        [divided_phone] = seperate_sequences(decreased_precision_phone, split_sequence_length);
        [divided_bs] = seperate_sequences(normalized_BS, split_sequence_length);

        % downsample data
        downsampling_rate = EEG.srate/100;
        for i=1:length(divided_phone)
            processed_phone{i,1} = downsample(divided_phone{i,1}, downsampling_rate);
            processed_BS{i,1}  = downsample(divided_bs{i,1}, downsampling_rate);
        end

    end
end
