function [decreased_precision_phone] = change_sequence_precision(Phone, pad_length)
%% The tap measurement may be off by about +/- 10 taps, this function pads
% the data with this difference
%
% **Usage:** [decreased_precision_phone] = change_sequence_precision(Phone, pad_length)
%
%
% Input(s):
%   - Phone = Phone taps
%   - pad_length = The number of 'taps' to be added before and after the real tap
%
% Output(s):
%   - decreased_precision_phone = Phone taps with the added pad_length around each tap
%
% Author: R.M.D. Kock, Leiden University

%%
decreased_precision_phone = zeros(size(Phone));
for i=1:length(Phone)
    if (Phone(i) == 1 && i+pad_length <= length(Phone) && i-pad_length >= 0)
        decreased_precision_phone(i:i+pad_length) = 1;
        %size(decreased_precision_phone(i:i+pad_length))
        decreased_precision_phone(i-pad_length:i) = 1;
    end
end
end
