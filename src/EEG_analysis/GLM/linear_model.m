function [ancova, indx] = linear_model(EEG_epoch,EEG_data, participant, indx, all_data, options)
%% Run GLM
%
% **Usage:** [model] = linear_model(all_eeg,epoch_window)
%
% Input(s):
%   - all_eeg = all EEG structs
%   - epoch_window = epoch window
%
% Output(s):
%   - model = LIMO model
%
ancova = {};

if options.type_ancova_mod
    Y_1 = EEG_data;
    [x_1] =  create_design_matrix_model(EEG_epoch);
else
    all_channels = all_data(strcmp(participant, [all_data(:,1)]), 2);
    all_channels_reshaped = cat(4, all_channels{:});
    % channel x time*freq x trials
    Y_1 = zeros(size(all_channels_reshaped,4), size(all_channels_reshaped,1)*size(all_channels_reshaped,2), size(all_channels_reshaped, 3));

    for pp_c=1:length(all_channels)
        x = all_channels{pp_c};
        Y_1(pp_c,:,:) = reshape(x, [size(x,1)*size(x,2), size(x,3)]);
    end

    eeg_epochs = all_data(strcmp(participant, [all_data(:,1)]), 3);
    [x_1] =  create_design_matrix_model(eeg_epochs{1});
end


Y_1(:, :, any(isnan(x_1), 2)) = [];
x_1(any(isnan(x_1), 2), :) = [];
%     figure; imagesc(x_1);
disp('train mod 1')
model = {};
for current_electrode = 1:size(Y_1, 1)
    Y_now = squeeze(Y_1(current_electrode, :, :))';
    model{current_electrode,1} = limo_glm(Y_now, x_1, 2, 0, 1, 'OLS', 'Time-Frequency', 0, size(Y_1,2));
end
ancova{indx, 1} = participant;
ancova{indx, 2} = model;
ancova{indx, 3} = x_1(:,3);
indx = indx + 1;
end