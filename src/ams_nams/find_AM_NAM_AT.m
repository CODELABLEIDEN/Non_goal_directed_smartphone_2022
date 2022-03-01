function [AMs_AT, NAMs_AT] = find_AM_NAM_AT(EEG, type, s_i,precision)
%% Calculates ERP per participant
%
% **Usage:** [AMs_AT, NAMs_AT] = find_AM_NAM_AT(EEG, type, s_i,precision)
%
% Input(s):
%   - EEG = EEG struct with epoched integral data
%   - type = name of event for artificial touch (e.g. type = '33')
%   - s_i = struct with locations of ams and nams
%   - precision = window in which to look for events
%
% Output(s):
%   - AMs_AT = locations of artificial touch ams
%   - NAMs_AT = locations of artificial touch nams
%
% Author: R.M.D. Kock, Leiden University
%
%%
eeg_event = EEG.event;
latencies_AT = [eeg_event(cellfun(@(x) contains(x,type),{eeg_event.type})).latency];
%%
AMs_AT = []; 
locs_am = s_i.AMs;
for i=1:length(locs_am)
    AMs_AT = [AMs_AT latencies_AT(latencies_AT <= locs_am(i)+precision & latencies_AT >= locs_am(i)-precision)];
end
%%
NAMs_AT = [];
locs_nam = s_i.NAMs;
for i=1:length(locs_nam)
    NAMs_AT = [NAMs_AT latencies_AT(latencies_AT <= locs_nam(i)+precision & latencies_AT >= locs_nam(i)-precision)];
end
end