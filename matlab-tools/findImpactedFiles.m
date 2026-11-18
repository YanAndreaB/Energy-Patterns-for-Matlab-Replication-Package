%% impactedFiles
% Author: jan-andrea.bard@unibe.ch
%
% impactedFiles(<funName>) finds all files on the Matlab path that can be
% called by calling the function <funName>. Only m-files that are not
% built-ins or other Matlab functions are found. The file names are listed
% in a cell array.
%
% Syntax:
% files = impactedFiles(myFun);
% impactedFiles myFun

function fileList = findImpactedFiles(fileName)
persistent excludedFunctions

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

tree = mtree(fullFileName,'-file');

% find function calls
calls = mtfind(tree,'Kind','CALL');
calls = calls.Left.strings';

% find parent class
classDef = mtfind(tree,'Kind','CEXPR');
parentClass = findParentClasses(classDef);

fileList = unique([calls;parentClass]);

originalList = unique(fileList);
originalList = setdiff(originalList,excludedFunctions);
fileList = originalList;
fileList = cellfun(@which,fileList,'UniformOutput',false);

% filter out built-in and Matlab functions
IDX1 = contains(fileList,matlabroot);
IDX2 = contains(fileList,'.mexw64');
IDX3 = contains(fileList,'built-in');
IDX = IDX1 | IDX2 | IDX3;
excludedFunctions = [excludedFunctions;originalList(IDX)]; % extend excluded functions
fileList = fileList(~IDX);
fileList(~isfile(fileList)) = [];
fileList(cellfun(@isempty,fileList)) = []; % remove empty cells
end

function parentClass = findParentClasses(node)
parentClass = {}; % default value
if ~node.isempty
    switch node.kind
        case {'CEXPR','LT'}
            parentClass = findParentClasses(node.Right);
        case 'AND'
            parentClass1 = findParentClasses(node.Right);
            parentClass2 = findParentClasses(node.Left);
            parentClass = [parentClass1;parentClass2];
        case 'ID'
            parentClass = node.strings;
    end
end
end
