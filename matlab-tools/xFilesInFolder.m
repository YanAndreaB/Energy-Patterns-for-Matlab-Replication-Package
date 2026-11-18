%% xFilesInFolder

function files = xFilesInFolder(folder,type)
files = dir(fullfile(folder,'**',['*.',type]));
% remove items that are a folder terminating on .<type>
files([files.isdir]) = [];
files = arrayfun(@(arg)fullfile(arg.folder,arg.name),files,'UniformOutput',false);
end
