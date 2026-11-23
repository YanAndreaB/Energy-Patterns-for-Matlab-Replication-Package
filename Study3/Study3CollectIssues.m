%% Study3CollectIssues
% collect code issues from files that are in the dynamic closure of the
% benchmark files.

%% 1. Preparations
rootFolder = projectRoot;
folderStudy3 = fullfile(rootFolder,'Study3');
cd(folderStudy3)

addpath(genpath(fullfile(rootFolder,'OverrideFunctions')))

projectFolder = 'GithubProjects';
load(fullfile(folderStudy3,'filesStudy3.mat'),'filesStudy3')
projectNames = regexp(filesStudy3.fileName,'(?<=__).*?(?=/)','match','once');
folderNames = regexp(filesStudy3.fileName,'.*?(?=/)','match','once');
functionNames = regexp(filesStudy3.fileName,'(?<=/)[^/]*(?=\.m)','match','once');

%% 2. collect issues
[~,patternIds] = patternInfo;
numFiles = height(filesStudy3);
data = struct('Successful',[], 'File',[],'DetectedPatterns',[],'PatternCount',[]);
data = repmat(data,numFiles,1);
for idx = 1:numFiles
    fprintf('idx: %d\n',idx)
    functionName = functionNames{idx};
    folder = folderNames{idx};

    % original folder
    folders{1} = fullfile(rootFolder,projectFolder,'MinedGithubProjects',folder);
    % optimized folder
    folders{2} = fullfile(rootFolder,projectFolder,'OptimizedGithubProjects',folder);

    issues = cell(size(folders));
    successful = false(size(folders));
    % loop over original and optimized file
    for idx3 = 1:numel(folders)
        [successful(idx3),issues{idx3}] = getIssues(folders{idx3},functionName,patternIds);
    end

    if all(successful)
        issuesOrig = issues{1};
        issuesOpt = issues{2};
        checkIdsOrig = issues{1}.CheckID;
        checkIdsOpt = issues{2}.CheckID;

        if ~isempty(issuesOpt)
            [~,issuesOrig.FullFilename] = fileparts(issuesOrig.FullFilename);
            [~,issuesOpt.FullFilename] = fileparts(issuesOpt.FullFilename);
            for idx2 = 1:height(issuesOpt)
                IDX = find(issuesOrig.CheckID == issuesOpt.CheckID(idx2) & ...
                    issuesOrig.FullFilename == issuesOpt.FullFilename(idx2),1);
                % remove unfixed issues
                issuesOrig(IDX,:) = [];
            end
        end

        checkIds = issuesOrig.CheckID;
        foundIssues = unique(checkIds);
        % remove ids that are not part of our investigated patterns from
        % categorical value set
        checkIds = categorical(checkIds,foundIssues);
    else
        foundIssues = [];
        checkIds = [];
    end

    % fill data into struct
    data(idx).Successful = all(successful);
    data(idx).File = functionName;
    data(idx).DetectedPatterns = foundIssues;
    data(idx).PatternCount = histcounts(checkIds);
end

%% Local functions

function [successful,issues] = getIssues(folder,functionName,patternIds)
cd(folder)
addpath(genpath(folder))

try
    collection = dynamicClosure(functionName);
    calledFiles = collection.files;
    executedLines = collection.executedLines;
    successful = true;
catch
    calledFiles = {};
    successful = false;
end

% loop over called files
issues = table;
try
    for idx2 = 1:numel(calledFiles)
        file = calledFiles{idx2};
        fileIssues = codeIssues(file).Issues;
        IDX = arrayfun(@(arg)ismember(arg,patternIds),fileIssues.CheckID);
        fileIssues = fileIssues(IDX,:);

        fileExecutedLines = executedLines{idx2};
        % only keep issues that were really touched during runtime
        IDX = arrayfun(@(arg)ismember(arg,fileExecutedLines),fileIssues.LineStart);
        fileIssues = fileIssues(IDX,:);
        issues = [issues;fileIssues]; %#ok<AGROW>
    end
catch
    successful = false;
end
rmpath(genpath(folder))
end
