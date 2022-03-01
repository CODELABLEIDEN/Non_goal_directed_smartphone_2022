function rename_add_suffix(path, suffix)
%% Rename LIMO saved files by adding suffix
%
% **Usage:** rename_add_suffix(path, action, suffix)
%
%  Input(s):
%   - path = path to saved LIMO file
%   - suffix = suffix to add behind file name
%
% Author: R.M.D. Kock, Leiden University

%%
x = split(genpath(path),':');
for folder=1:length(x)
    files = dir(x{folder});
    data_files = {files.name};
    data_files = data_files(~ismember(data_files,{'.','..'}));
    for file=1:length(data_files)
        if contains(data_files{file}, '.')
            file_name = split(data_files{file}, '.');
            movefile(sprintf('%s/%s', x{folder},data_files{file}),  sprintf('%s/%s_%s.%s', x{folder}, file_name{1},suffix,file_name{2}))
        end
    end
end
movefile(sprintf('%s/H0', path),  sprintf('%s/H0_%s', path,suffix))
end