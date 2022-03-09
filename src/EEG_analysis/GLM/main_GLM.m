%% load epoched event
path_upper = '/home/ruchella/non_attribute_movement_and_EEG/data/all_epochs';
all_epochs = load_EEG_checkpoints(path_upper, 'all_epochs', 'all_epochs', 'save_results', 0);
%% load EEG data
ancova = load_EEG_checkpoints('/home/ruchella/non_attribute_movement_and_EEG/data/ancova', 'ancova', 'ancova', 'save_results', 0);
C = ismember(unique(ancova(:,1), 'stable'),unique(all_epochs(:,1),'stable'));
ancova_sel = ancova(C,:);
%%
indx = 1;
all_data = {};
for j=1:size(all_epochs,1)
% for j=1:1
    [all_data, indx] = linear_model(ancova_sel{j,8},ancova_sel{j,10}, ancova_sel{j,1}, indx, all_data, []);
end
%%
[mask, cluster_p, one_sample] = t_test_linear_mod(ancova_models, 2, '/home/ruchella/non_attribute_movement_and_EEG/data/glm');
%%
ancova_ersp = load_EEG_checkpoints('/home/ruchella/non_attribute_movement_and_EEG/data/ancova/ersp', 'ancova_ersp', 'ancova_ersp', 'save_results', 0);
[all_data] = load_EEG_checkpoints('/home/ruchella/non_attribute_movement_and_EEG/data/erp_ersp_3/ersp', 'ersp', 'all_data', 'save_results', 0);
C = ismember(unique(ancova_ersp(:,1), 'stable'),unique(all_data(:,1),'stable'));
ancova_ersp_sel = ancova_ersp(C,:);
%%
[mask, cluster_p, one_sample] = t_test_linear_mod(ancova_ersp_sel, 2, '/home/ruchella/non_attribute_movement_and_EEG/data/ancova/ersp/ancova_ersp_glm');