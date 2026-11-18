
function folderNames = dir2folderNames(rootFolder)
% converts search of dir command to a list of top-level-folders in current
% directory

% check if there is an input argument
if ~nargin
    rootFolder = pwd;
end
% Get a list of directories in the current folder
folderList = dir(rootFolder);
% Remove '.' and '..' entries from folderList
isDotFolder = strcmp({folderList.name}, '.') | strcmp({folderList.name}, '..');
folderList(isDotFolder) = [];
folderNames = {folderList([folderList.isdir]).name}';
end
