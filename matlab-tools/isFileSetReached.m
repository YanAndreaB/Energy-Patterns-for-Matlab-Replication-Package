%% fileOrbit
% Author: jan-andrea.bard@unibe.ch
% Dependencies: impactedFiles.m
% 
% isFileSetReached(<funName>,<fileSet>) returns true if a file from the set
% fileSet is reached by calling the function <funName>. Only m-files that
% are not built-ins or other Matlab functions are found. The file names are
% listed in a cell array. fileSet must be a cell array of file names.
% 
% Syntax:
% result = isFileSetReached(myFun,{myOtherFun});

function result = isFileSetReached(fileName,fileSet,varargin)
persistent collection visitedFiles
if isempty(varargin)
    collection = {};
    visitedFiles = {};
end

fileName = which(fileName);
if isempty(fileName)
    disp('File not found on Matlab path.')
    return
end

orbit = {};
if strcmp(fileName(end-1:end),'.m')
    orbit = findImpactedFiles(fileName);
    if ~isempty(intersect(orbit,fileSet))
        result = true;
        return
    else
        result = false;
    end
else
    result = false;
end
visitedFiles = [visitedFiles;fileName]; % extend visited files

if ~isempty(orbit)
    collection = unique([collection;orbit]); % extend collection

    for idx = 1:numel(orbit)
        newFile = orbit{idx};
        if isfile(newFile) && ~ismember(newFile,visitedFiles)
            result = isFileSetReached(newFile,fileSet,true); % recursion step
            if result
                return
            end
        end
    end
end
end
