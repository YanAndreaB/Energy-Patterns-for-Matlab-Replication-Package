%% EnergyTestStudy3

%% 1. Collect Total Issues
rootFolder = projectRoot;
folderStudy3 = fullfile(rootFolder,'Study3');
cd(folderStudy3)

pathToEnergyTools = fullfile(rootFolder,'energy-tools');
pathToMatlabTools = fullfile(rootFolder,'general-matlab-files');
pathToGeneralMatlabFiles = fullfile(rootFolder,'matlab-tools');
folderHelpfunctions = fullfile(rootFolder,'HelpFunctions');
folderGithubProjects = fullfile(rootFolder,'GithubProjects');
folderMinedProjects = fullfile(folderGithubProjects,'MinedGithubProjects');
folderOptimizedProjects = fullfile(folderGithubProjects,'OptimizedGithubProjects');

folders = dir2folderNames(folderMinedProjects)';

numFolders = numel(folders);
totalIssues = table;
for idx = 1:numFolders
    folderPath = fullfile(folderMinedProjects, folders{idx});
    summary = codeIssues(folderPath);
    % get non-suppressed issues
    tmpIssues = summary.Issues;
    tmpIssues.isSuppressed = false(size(tmpIssues,1),1);
    % get suppressed issues
    tmpSuppressedIssues = summary.SuppressedIssues;
    tmpSuppressedIssues = removevars(tmpSuppressedIssues,'Suppression');
    tmpSuppressedIssues.isSuppressed = true(size(tmpSuppressedIssues,1),1);

    % concatenate
    totalIssues = [totalIssues;tmpIssues;tmpSuppressedIssues]; %#ok<AGROW>
end

%% 2. Get Fixable Issues
autoFixCheckIds = { ...
    'AND2', ...
    'CCAT', ...
    'FNDSB', ...
    'ISCL', ...
    'OR2', ...
    };

manualFixCheckIds = { ...
    'ST2NM', ...
    'GFLD', ...
    'AGROW', ...
    'SAGROW', ...
    'EXIST', ...
    };

checkIds = [autoFixCheckIds,manualFixCheckIds];
% Filter totalIssues based on checkIds
fixableIssues = totalIssues(ismember(totalIssues.CheckID, checkIds), :);
save(fullfile(folderStudy3,'issues.mat'),'fixableIssues')

%% 3. Replace %#ok Annotations
% This step is to unsuppress code analyzer warnings.

cd(fullfile(folderMinedProjects))

fileNames = mFilesInPwd;
str1 = '%#ok';
str2 = '% #ok';
counter = 0;
for idx = 1:numel(fileNames)
    fileID = fopen(fileNames{idx},'r');
    res = fscanf(fileID,'%c');
    fclose(fileID);

    if count(res,str1) > 0
        counter = counter + 1;
        res = replace(res,str1,str2);
        fileID = fopen(fileNames{idx},'w');
        fwrite(fileID,res);
        fclose(fileID);
    end
end

%% 4. Copy files to folder OptimizedGithubProjects
cd(folderGithubProjects)
copyfile('MinedGithubProjects','OptimizedGithubProjects')

% This step might alternatively be done manually in Linux shell:
% cp MinedGithubProjects OptimizedGithubProjects

%% 5. Optimize Files with Autofix option
% This section optimizes files that contain code issues that can be fixed
% with the codeIssues.fix method. This procedure had to be re-iterated
% three times. codeIssues.fix seems not to fix all issues in one go. In one
% run the projects that have auto-fix issues are collected in projectList.
% For the next run oldProjectList gets the values of projectList and the
% iteration is proceeded until the array projectList hasn't "shrunk" after
% the run.

cd(folderOptimizedProjects)

folders = dir2folderNames;
counter = 0;
projectList = [];
for idx = 1:numel(folders)
    folderPath = fullfile(folderOptimizedProjects, folders{idx});
    summary = codeIssues(folderPath);
    IDX = ismember(summary.Issues.CheckID, autoFixCheckIds);
    checkIds = string(unique(summary.Issues.CheckID(IDX)));
    if ~isempty(checkIds)
        counter = counter + 1;
        projectList = [projectList,idx]; %#ok<AGROW>
        % Optimize files with fixable issues
        summary.fix(checkIds);
    end
end

save(fullfile(folderStudy3,'issues.mat'),'projectList','-append')

%% 5.b) Loop through projects that have not been optimized in 5.
% For some unknonw reason not all autofixable issues have been fixed under
% step 5. To make sure that no auto-fixable issue remains, loop again
% through projects that have unsolved issues.

cd(folderOptimizedProjects)

load(fullfile(folderStudy3,'issues.mat'),'projectList')
folders = dir2folderNames;
counter = 0;
projectList2 = [];

for idx = projectList
    folderPath = fullfile(folderOptimizedProjects, folders{idx});
    summary = codeIssues(folderPath);
    IDX = ismember(summary.Issues.CheckID, autoFixCheckIds);
    checkIds = string(unique(summary.Issues.CheckID(IDX)));
    if ~isempty(checkIds)
        fixability = string(summary.Issues.Fixability(IDX));
        if ismember("auto",fixability)
            % there is an autofixable issue
            counter = counter + 1;
            projectList2 = [projectList2,idx]; %#ok<AGROW>
            % Optimize files with manual fixable issues
            summary.fix(checkIds);
        end
    end
end

% If search was successful, counter remains zero, no auto-fixable issue
% remained.

%% 6. a) Optimize Files (Preparation)
% This step is to optimize files with self-crafted automated fixes - with
% the utility EnergyFileOptimizer.m

cd(folderOptimizedProjects)

files = mFilesInPwd;
startIdx = 1;
endIdx = numel(files);
counter = 0;
fileList = [];
failedFiles = {};

%% 6.b) Optimize Files
for idx = startIdx:endIdx

    % It might take about 3 hours for 1015 repos

    if mod(idx,100) == 0
        fprintf('%d\n',idx)
    end
    EFO = EnergyFileOptimizer(files{idx});
    try
        fileOptimized = EFO.optimize;
    catch err
        fileOptimized = false;
        failedFiles = [failedFiles; files{idx}]; %#ok<AGROW>
    end
    if fileOptimized
        counter = counter + 1;
        fileList = [fileList,idx]; %#ok<AGROW>
    end
end

optimizedFilesList = files(fileList);

%% 7. Run files to estimate running time
load(fullfile(folderStudy3,'filesStudy3.mat'),'filesStudy3')
files = fullfile(folderOptimizedProjects,filesStudy3.fileName);
for idx = 1:numel(files)
    t0 = tic;
    runFile(files{idx},1)
    t1 = toc(t0);

    if t1 < 1
        t1 = timeit(@()runFile(files{idx},1));
    end
    filesStudy3.elapsedTime(idx) = t1;
end
save(fullfile(folderStudy3,'filesStudy3.mat'),'filesStudy3')

%% 8. a) Run Energy Experiments (preparation)
runningProjectFolder = fullfile(folderGithubProjects,'RunningProject');
if ~isfolder(runningProjectFolder)
    mkdir(runningProjectFolder)
end

load(fullfile(folderStudy3,'filesStudy3.mat'),'filesStudy3')
files = filesStudy3;

% random order
rng default
numFiles = height(files);
order = randperm(numFiles,numFiles);
files = files(order,:);

elapsedTime = files.elapsedTime;
erroringProjects = [];
errorMessages = {};

%% 8. b) Loop through files
for idx = 1:height(files)
    % restore default path
    restoredefaultpath
    % matlab tools, general matlab files, energy tools
    addpath(genpath(pathToEnergyTools))
    addpath(genpath(pathToMatlabTools))
    addpath(genpath(pathToGeneralMatlabFiles))
    % energy pattern paths
    addpath(genpath(fullfile(rootFolder,'HelpFunctions')))
    addpath(fullfile(rootFolder,'MatFiles'))
    warning off
    addpath(genpath(fullfile(rootFolder,'OverrideFunctions')))
    warning on
    
    % close all windows
    close all force
    % close all simulink projects
    bdclose all

    cd(runningProjectFolder)

    optimizedFile = files.fileName{idx};
    originalFile = replace(optimizedFile,'OptimizedGithubProjects','MinedGithubProjects');
    originalProject = getProjectFolder(originalFile);
    optimizedProject = getProjectFolder(optimizedFile);
    [~,originalShortName] = fileparts(originalFile);
    [~,optimizedShortName] = fileparts(optimizedFile);
    [~,project] = fileparts(originalProject);
    fileDescription = [project,'__',optimizedShortName,'__'];

    cleanFolders(rootFolder,project)

    clc force
    timeStamp = datetime;
    fprintf('Experiment %d: %s / %s\n',idx,project,timeStamp)

    TestingClass = EnergyTestScript; % real measurement
    % TestingClass = EnergyTestRun; % for testing purpose

    TestingClass.prepareA = @()prepareProject(originalProject,folderGithubProjects);
    TestingClass.prepareB = @()prepareProject(optimizedProject,folderGithubProjects);
    TestingClass.cleanUpA = @()cleanUpRunningProject(folderGithubProjects);
    TestingClass.cleanUpB = @()cleanUpRunningProject(folderGithubProjects);

    numRuns = ceil(4 / elapsedTime(idx)); % Aiming at a running time of total 2-4 seconds
    TestingClass.benchmarkA = @()runFile(originalShortName,numRuns);
    TestingClass.benchmarkB = @()runFile(optimizedShortName,numRuns);

    TestingClass.fileDescription = fileDescription;
    TestingClass.matFileFolder = rootFolder;
    try
        TestingClass.execute
    catch err
        errorMessages{end + 1} = err.message; %#ok<SAGROW>
        erroringProjects(end + 1) = idx; %#ok<SAGROW>
    end
end

% clean up running project folder
cleanUpRunningProject(folderGithubProjects)

%% 9. a) Count number of script files (preparation)
load filesInStaticClosure.mat fileNames

cd(folderMinedProjects)
files = mFilesInPwd;
filesInClosure = replace(fileNames,'OptimizedGithubProjects','MinedGithubProjects');

%% 9. b) Count number of script files
counter = 0;
counterInClosure = 0;
for idx = 1:numel(files)
    if mod(idx,1000) == 0
        fprintf('%d\n',idx)
    end
    tree = mtree(files{idx},'-file');
    if ~tree.isempty
        kind = tree.root.kind;
        if ~strcmp(kind,'FUNCTION')
            counter = counter + 1;
            if ismember(files{idx},filesInClosure)
                counterInClosure = counterInClosure + 1;
            end
        end
    end
end

%% 10. Count number of lines of code
numLines = 0;
numLinesInClosure = 0;
for idx = 1:numel(files)
    if mod(idx,1000) == 0
        fprintf('%d\n',idx)
    end
    tree = mtree(files{idx},'-file');
    if ~tree.isempty
        str = tree.tree2str;
        newNumLines = numel(regexp(str,newline));
        numLines = numLines + newNumLines;
        if ismember(files{idx},filesInClosure)
            numLinesInClosure = numLinesInClosure + newNumLines;
        end
    end
end

%% Local functions for running energy consumption experiments

function cleanFolders(rootFolder,projectFolder)
originalFolderName = 'MinedGithubProjects';
optimizedFolderName = 'OptimizedGithubProjects';
originalFolder = fullfile(rootFolder,originalFolderName);
optimizedFolder = fullfile(rootFolder,optimizedFolderName);
originalProjectFolder = fullfile(originalFolder,projectFolder);
optimizedProjectFolder = fullfile(optimizedFolder,projectFolder);

% delete excessive files that are present in optimizedFolder but not in
% originalFolder
fileTypes = {'m','txt','dat','html','css','log','mat','md','csv'};
for idx = 1:numel(fileTypes)
    deleteExcessFiles(originalFolder,optimizedFolder,originalProjectFolder,optimizedProjectFolder,fileTypes{idx})
    deleteExcessFiles(optimizedFolder,originalFolder,optimizedProjectFolder,originalProjectFolder,fileTypes{idx})
end

% delete all empty folders recursively
deleteEmptyFolders(originalProjectFolder)
deleteEmptyFolders(optimizedProjectFolder)
end

function deleteExcessFiles(folder1,folder2,projectFolder1,projectFolder2,type)
xFiles1 = xFilesInFolder(projectFolder1,type);
xFiles2 = xFilesInFolder(projectFolder2,type);

xFiles1 = replace(xFiles1,folder1,'');
xFiles2 = replace(xFiles2,folder2,'');
excessFiles = setdiff(xFiles2,xFiles1);
excessFiles = fullfile(folder2,excessFiles);
if ~isempty(excessFiles)
    cellfun(@delete,excessFiles)
end
end

function deleteEmptyFolders(parentFolder)
% delete empty folders from parentFolder (but keep root)

allFolders = dir(fullfile(parentFolder,'**'));
allFolders(~[allFolders.isdir]) = []; % keep only directories
% remove . and ..
allFolders(ismember({allFolders.name},{'.','..'})) = [];
% sort by depth (deepest first) so nested empty folders are removed
paths = fullfile({allFolders.folder},{allFolders.name});
depths = cellfun(@(str)numel(strfind(str,filesep)), paths);
[~,order] = sort(depths,'descend');
paths = paths(order);

for idx = 1:numel(paths)
    thisPath = paths{idx};
    % list contents
    contents = dir(thisPath);
    % ignore . and ..
    contents(ismember({contents.name},{'.','..'})) = [];
    % if empty or contains only hidden folders (. and .. removed) then
    % delete
    if isempty(contents)
        rmdir(thisPath)
    end
end
end
