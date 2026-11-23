
function collectionTable = dynamicClosure(fun)
% Start tracking function/file usage by setting up MATLAB profiler to log
% file calls
profile on

feval(fun)

p = profile('info');
profile off

% Collect unique file names (exclude <anonymous> or MATLAB builtin
% entries without file)
% calledFiles = unique({p.FunctionTable.FileName}');
calledFiles = {p.FunctionTable.FileName}';

% remove functions in matlabroot
expr = replace(matlabroot,'\','\\');
IDX = cellfun(@(arg)isempty(regexp(arg,expr,'once')),calledFiles);
calledFiles = calledFiles(IDX);
functionTable = p.FunctionTable(IDX);

% remove this file
IDX = calledFiles == string(which(mfilename));
calledFiles(IDX) = [];
functionTable(IDX) = [];

% remove caller files
dbInfo = dbstack;
for idx = 2:numel(dbInfo)
    file = dbInfo(idx).file;
    IDX = calledFiles == string(which(file));
    calledFiles(IDX) = [];
    functionTable(IDX) = [];
end

% remove override functions
expr = replace(fullfile(gitLabPath,'energy-patterns','OverrideFunctions'),'\','\\');;
IDX = cellfun(@(arg)isempty(regexp(arg,expr,'once')),calledFiles);
calledFiles = calledFiles(IDX);
functionTable = functionTable(IDX);

% remove mex-functions
IDX = cellfun(@(arg)isempty(regexp(arg,'mexw64','once')),calledFiles);
calledFiles = calledFiles(IDX);
functionTable = functionTable(IDX);

% pool executed lines
[calledFiles,order] = sort(calledFiles);
functionTable = functionTable(order);
collection = cell(0,2);
if ~isempty(calledFiles)
    collection{1,1} = calledFiles{1};
    collection{1,2} = functionTable(1).ExecutedLines(:,1);
    counter = 1;
    for idx = 2:numel(calledFiles)
        if strcmp(calledFiles{idx},calledFiles{idx - 1})
            % append executed lines to last file in collection
            collection{counter,2} = unique([collection{counter,2};functionTable(idx).ExecutedLines(:,1)]);
        else
            counter = counter + 1;
            % add a new file and its executed lines to collection
            collection{counter,1} = calledFiles{idx};
            collection{counter,2} = functionTable(idx).ExecutedLines(:,1);
        end
    end
end
files = collection(:,1);
executedLines = collection(:,2);
collectionTable = table(files,executedLines);
end
