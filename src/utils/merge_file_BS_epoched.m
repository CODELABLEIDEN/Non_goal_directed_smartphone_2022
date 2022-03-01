function [epoched_bs_around_AMs,epoched_bs_around_NAMs] = merge_file_BS_epoched(bs_to_tap_predictions, window,s_i)
BS = bs_to_tap_predictions(:,2);
epoched_bs_around_AMs_i = cellfun(@(BS,s_i) getepocheddata(BS, s_i.AMs, window), BS,s_i,'UniformOutput',false);
epoched_bs_around_NAMs_i = cellfun(@(BS,s_i) getepocheddata(BS, s_i.NAMs, window), BS,s_i,'UniformOutput',false);
k = 1;
while k <= size(bs_to_tap_predictions(:,1),1)
    x = find(contains(bs_to_tap_predictions(:,1),bs_to_tap_predictions{k,1}));
    k = k + length(x);
    if length(x) > 1
        am = []; nam = [];
        for j=1:length(x)
            a = epoched_bs_around_AMs_i{x(j)};
            n = epoched_bs_around_NAMs_i{x(j)};
            am = [am ; a];
            nam = [nam ; n];
            epoched_bs_around_AMs_i{x(j)} = [];
            epoched_bs_around_NAMs_i{x(j)} = [];
        end
        epoched_bs_around_AMs_i{x(1)}  = am;
        epoched_bs_around_NAMs_i{x(1)} = nam;
    end
end
epoched_bs_around_AMs = epoched_bs_around_AMs_i(~cellfun('isempty',epoched_bs_around_AMs_i) & ~cellfun('isempty',epoched_bs_around_NAMs_i));
epoched_bs_around_NAMs = epoched_bs_around_NAMs_i(~cellfun('isempty',epoched_bs_around_AMs_i) & ~cellfun('isempty',epoched_bs_around_NAMs_i));
end