function [ancova, indx] = generate_EEG_ancova(EEG, b,participant, indx, ancova, options)
%% Creates a placeholder cell with the datasets of all participants for plotting of results
%
% **Usage:**

ancova{indx,1} = participant;
ancova{indx,2} = EEG.data;
ancova{indx,3} = EEG.Aligned.BS_to_tap.threshold_i;
indx = indx +1;
end
