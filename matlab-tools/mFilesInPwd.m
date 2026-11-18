%% mFilesInPwd

function files = mFilesInPwd
files = dir('**/*.m');
% remove items that are a folder terminating on .m
files([files.isdir]) = [];
files = arrayfun(@(arg)fullfile(arg.folder,arg.name),files,'UniformOutput',false);
end
