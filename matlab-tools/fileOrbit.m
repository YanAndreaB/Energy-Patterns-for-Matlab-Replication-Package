%% fileOrbit
% Author: jan-andrea.bard@unibe.ch
% Dependencies: impactedFiles.m
% 
% fileOrbit(<funName>) finds the collection of all files on the Matlab path
% that can be called (directly or indirectly) by calling the function
% <funName>. Only m-files that are not built-ins or other Matlab functions
% are found. The file names are listed in a cell array.
% 
% Syntax:
% files = fileOrbit(myFun);
% fileOrbit myFun

function orbit = fileOrbit(fileName,varargin)
persistent collection visitedFiles
if isempty(varargin)
    collection = {};
    visitedFiles = {};
end

fullFileName = which(fileName);
if isempty(fullFileName)
    % full file name might be provided already. The file might be located
    % in a library folder (+folderName). These folders don't get added to
    % the Matlab path
    fullFileName = fileName;
end

if isempty(fullFileName)
    disp('File not found on Matlab path.')
    return
end

orbit = {};
if strcmp(fullFileName(end-1:end),'.m')
    orbit = findImpactedFiles(fullFileName);
end
visitedFiles = [visitedFiles;fullFileName]; % extend visited files

if ~isempty(orbit)
    collection = unique([collection;orbit]); % extend collection

    for idx = 1:numel(orbit)
        newFile = orbit{idx};
        if isfile(newFile) && ~ismember(newFile,visitedFiles)
            if isempty(fileOrbit(newFile,true)) % recursion step
                return
            end
        end
    end
end

orbit = collection;
end
