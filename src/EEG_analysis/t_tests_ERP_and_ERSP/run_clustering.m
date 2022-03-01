function [mask, cluster_p] = run_clustering(LIMO_paths, significance_threshold, channeighbstructmat, tf, paired)
%% Prepare data and calls LIMO cluster correction 
%
% **Usage:** [mask, cluster_p] = run_clustering(LIMO_paths, significance_threshold, channeighbstructmat, tf, paired)
%
% Input(s):
%   - LIMO_paths = path where data is saved
%   - significance_threshold = significance threshold for the clustering
%   - channeighbstructmat (name value argument default will load the file if present on path) = struct with information on what electrodes are neighbors with each other 
%   - tf (logical) = 1 if time frequency analysis and 0 if erp analysis
%   - paired (logical) = 1 if paired ttest is used and 0 if one sample ttest
%
% Output(s):
%   - maks = a binary matrix of significant/non-significant cells
%   - cluster_p = a matrix of cluster corrected p-values
%
% Requires:
%   - limo_ft_cluster_test.m
%   - limo_ft_cluster_correction.m
%
% Author: R.M.D. Kock, Leiden University

%%
split_path = split(LIMO_paths, '/');
event = split_path{end};
if paired
    load(sprintf('%s/paired_samples_ttest_parameter_1.mat',LIMO_paths));
    load(sprintf('%s/H0/H0_paired_samples_ttest_parameter_1',LIMO_paths));
    one_sample = paired_samples;
    H0_one_sample = H0_paired_samples;
else
    load(sprintf('%s/one_sample_ttest_parameter_1.mat',LIMO_paths));
    load(sprintf('%s/H0/H0_one_sample_ttest_parameter_1',LIMO_paths));
end
if tf
    one_sample_reshaped = limo_tf_4d_reshape(one_sample, [64, 50, 200,  5]);
    H0_one_sample_M_reshaped = limo_tf_4d_reshape(squeeze(H0_one_sample(:,:,1,:)), [64, 50, 200, size(H0_one_sample,4)]);
    
    % F values
    M = squeeze(one_sample_reshaped(:, :, :, 4)) .^ 2;
    % P values
    P = squeeze(one_sample_reshaped(:, :, :, 5));
    % F values under h0
    bootM = H0_one_sample_M_reshaped .^ 2;
    % P values under h0
    bootP = limo_tf_4d_reshape(squeeze(H0_one_sample(:,:,2,:)), [64, 50, 200, size(H0_one_sample,4)]);
    [mask,cluster_p] = limo_ft_cluster_correction(M,P,bootM,bootP,channeighbstructmat,2,significance_threshold);
else
    % F values
    M = squeeze(one_sample(:, :, 4)) .^ 2;
    % P values
    P = squeeze(one_sample(:, :, 5));
    % F values under h0
    bootM = squeeze(H0_one_sample(:,:,1,:)) .^ 2;
    % P values under h0
    bootP = squeeze(H0_one_sample(:,:,2,:));
    [mask,cluster_p] = limo_cluster_correction(M,P,bootM,bootP,channeighbstructmat,2,significance_threshold);
end
end


% 1 one_sample_parameter_X (channels, frames [time, freq or freq-time], [mean value, se, df, t, p])
% H0_one_sample_ttest_parameter_X (channels, frames, [T values under H0, p values under H0], LIMO.design.bootstrap)
% (channel*frames*beta)
% INPUTS: M = matrix of observed F values (channel*[]*[])
%         P = matrix of observed p values
%         (note for a single electrode the format is 1*[]*[])
%         bootM = matrix of F values for data under H0 (channel*[]*[]*MC)
%         bootP = matrix of F values for data under H0
%         (note for a single electrode the format is 1*[]*[]*MC)
%         neighbouring_matrix is the bianry matrix that define how to cluster the 1st dim of M
%         MCC = 2 (spatial-temporal clustering) or 1 (temporal clustering)
%         p = threshold to apply (note this applied to create clusters and to  threshold the cluster map)