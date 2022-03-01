function [divided_data] = seperate_sequences(sequence, sequence_length)
%% Seperates input data into multiple sequences of a chosen length
%
% **Usage:** [divided_phone] = seperate_sequences(sequence, sequence_length)
%
% Input(s):
%   - sequence = data to be seperated into sequences (BS or Phone data)
%   - sequence_length = length to seperate sequences by
%
% Output(s):
%   - divided_data: cell where each row contains one of the seperated
%   sequences.
%
% Author: R.M.D. Kock, Leiden University

%%
divided_data = {};
index = 1;
for (i=1:ceil(length(sequence)/sequence_length))
    if (index > length(sequence)-sequence_length)
        divided_data{i,1} = sequence(index:end);
    else
        divided_data{i,1} = sequence(index:index+sequence_length-1);
    end
    index = index+sequence_length;
end

end
