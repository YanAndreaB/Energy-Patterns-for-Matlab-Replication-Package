%% EnergyTestStudy3

%% 1. Set Folders
disp 'Set Folders'

rootFolder = projectRoot;
folderStudy3 = fullfile(rootFolder,'Study3');
cd(folderStudy3)

pathToEnergyTools = fullfile(rootFolder,'energy-tools');
pathToMatlabTools = fullfile(rootFolder,'general-matlab-files');
pathToGeneralMatlabFiles = fullfile(rootFolder,'matlab-tools');
folderGithubProjects = fullfile(rootFolder,'GithubProjects');
folderMinedProjects = fullfile(folderGithubProjects,'MinedGithubProjects');
folderOptimizedProjects = fullfile(folderGithubProjects,'OptimizedGithubProjects');

load(fullfile(folderStudy3,'filesStudy3.mat'),'filesStudy3')
projectNames = regexp(filesStudy3.fileName,'(?<=__).*?(?=/)','match','once');
fileNames = regexp(filesStudy3.fileName,'(?<=/)[^/]*(?=$)','match','once');
folderNames = cell(size(projectNames));
for idx = 1:numel(projectNames)
    folderNames{idx} = [num2str(idx),'_',projectNames{idx}];
    if ~isfolder(folderNames{idx})
        mkdir(folderNames{idx})
    end
end

autoFixCheckIds = { ...
    'AND2', ...
    'CCAT', ...
    'FNDSB', ...
    'ISCL', ...
    'OR2', ...
    };

%% 2.a) Optimize Files with Autofix option
% This section optimizes files that contain code issues that can be fixed
% with the codeIssues.fix method. This procedure had to be re-iterated
% three times. codeIssues.fix seems not to fix all issues in one go. In one
% run the projects that have auto-fix issues are collected in projectList.
% For the next run oldProjectList gets the values of projectList and the
% iteration is proceeded until the array projectList hasn't "shrunk" after
% the run.
disp 'Optimize Files with Autofix option'

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

%% 2.b) Loop through projects that have not been optimized in 2.a).
% For some unknonw reason not all autofixable issues have been fixed under
% step 5. To make sure that no auto-fixable issue remains, loop again
% through projects that have unsolved issues.
% Repeat this step until counter stays zero.
disp 'Loop through projects that have not been optimized in 2.a)'

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

%% 3. a) Optimize Files (Preparation)
% This step is to optimize files with self-crafted automated fixes - with
% the utility EnergyFileOptimizer.m
disp 'Optimize Files (Preparation)'

cd(folderOptimizedProjects)

files = mFilesInPwd;
startIdx = 1;
endIdx = numel(files);
counter = 0;
fileList = [];
failedFiles = {};

%% 3.b) Optimize Files
disp 'Optimize Files'

for idx = startIdx:endIdx

    % It might take about 3 hours for 1015 repos

    if mod(idx,100) == 0
        fprintf('%d\n',idx)
    end
    EFO = EnergyFileOptimizer(files{idx});
    try
        warning off % to suppress warnings about syntax errors
        fileOptimized = EFO.optimize;
        warning on
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

%% 4. Run files to estimate running time
disp 'Run files to estimate running time'

warning off
addpath(genpath(fullfile(rootFolder,'OverrideFunctions')))
warning on

load(fullfile(folderStudy3,'filesStudy3.mat'),'filesStudy3')
files = fullfile(folderOptimizedProjects,filesStudy3.fileName);
erroringFiles = [];
for idx = 1:numel(files)
    folder = getProjectFolder(files{idx});
    warning off
    addpath(genpath(folder))
    warning on

    try
        t0 = tic;
        runFile(files{idx},1)
        t1 = toc(t0);

        if t1 < 1
            t1 = timeit(@()runFile(files{idx},1));
        end
    catch
        erroringFiles = [erroringFiles,idx]; %#ok<AGROW>
    end
    filesStudy3.elapsedTime(idx) = t1;

    warning off
    rmpath(genpath(folder))
    warning on
end
save(fullfile(folderStudy3,'filesStudy3.mat'),'filesStudy3')

%% 5. a) Run Energy Experiments (preparation)
disp 'Run Energy Experiments (preparation)'

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
files.fileName = fullfile(folderOptimizedProjects,files.fileName);

elapsedTime = files.elapsedTime;
erroringProjects = [];
errorMessages = {};

%% 5. b) Loop through files
disp 'Loop through files'

for idx = 1:height(files)
    % restore default path
    restoredefaultpath
    % matlab tools, general matlab files, energy tools
    addpath(genpath(pathToEnergyTools))
    addpath(genpath(pathToMatlabTools))
    addpath(genpath(pathToGeneralMatlabFiles))
    addpath(rootFolder) % without genpath
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
    TestingClass.matFileFolder = fullfile(folderStudy3,folderNames{idx});
    try
        TestingClass.execute
    catch err
        errorMessages{end + 1} = err.message; %#ok<SAGROW>
        erroringProjects(end + 1) = idx; %#ok<SAGROW>
    end
end

% clean up running project folder
cleanUpRunningProject(folderGithubProjects)

%% Run script Study3CollectIssues
disp 'Run script Study3CollectIssues'

Study3CollectIssues

%% 6. Save table as CSV
disp 'Save table as CSV'

energyContentRow = '%d %s %s %s %0.2fJ %0.2fJ %0.2f%%';
timeContentRow = '%d %s %s %s %0.2fs %0.2fs %0.2f%%';

load(fullfile(folderStudy3,'collectedIssues.mat'),'data');
patternCount = {data.PatternCount}';
checkId = {data.DetectedPatterns}';
IDX = cellfun(@ischar,checkId);
checkId(IDX) = cellfun(@(arg){arg},checkId(IDX),'UniformOutput',false);
checkId = cellfun(@(outerArg1,outerArg2)strjoin(sort( ...
    cellfun(@(arg,arg2)[arg,'~(',num2str(arg2),')'],outerArg1,num2cell(outerArg2),'UniformOutput',false)),', '), ...
    checkId, patternCount, 'UniformOutput',false);

newTable = cell(2 * height(filesStudy3),7);
for idx = 1:height(filesStudy3)
    res = dir(fullfile(folderNames{idx},'*processed.mat'));
    fileName = fullfile(res.folder,res.name);
    loadRes = load(fileName,'mean*_b','mean*_t','ratio_b','ratio_t');
    energyRow = sprintf(energyContentRow,idx,fileNames{idx},projectNames{idx},checkId{idx}, loadRes.mean1_b,loadRes.mean2_b,(1 - loadRes.ratio_b) * 100);
    timeRow = sprintf(timeContentRow,idx,fileNames{idx},projectNames{idx},'check-id', loadRes.mean1_t,loadRes.mean2_t,(1 - loadRes.ratio_t) * 100);
    newTable(2 * idx - 1,:) = split(energyRow,' ');
    newTable(2 * idx,:) = split(timeRow,' ');
end
newTable = cell2table(newTable);
newTable.Properties.VariableNames = {'Row-Num','File_Name','Project_Name','Check-ID','Non-fixed_Recommendation','Fixed_Recommendation','Gain/Loss'};
writetable(newTable,'ResultsStudy3.csv')

% %% 7. a) Count number of script files (preparation)
% load filesInStaticClosure.mat fileNames
% 
% cd(folderMinedProjects)
% files = mFilesInPwd;
% filesInClosure = replace(fileNames,'OptimizedGithubProjects','MinedGithubProjects');
% 
% %% 7. b) Count number of script files
% counter = 0;
% counterInClosure = 0;
% for idx = 1:numel(files)
%     if mod(idx,1000) == 0
%         fprintf('%d\n',idx)
%     end
%     tree = mtree(files{idx},'-file');
%     if ~tree.isempty
%         kind = tree.root.kind;
%         if ~strcmp(kind,'FUNCTION')
%             counter = counter + 1;
%             if ismember(files{idx},filesInClosure)
%                 counterInClosure = counterInClosure + 1;
%             end
%         end
%     end
% end
% 
% %% 8. Count number of lines of code
% numLines = 0;
% numLinesInClosure = 0;
% for idx = 1:numel(files)
%     if mod(idx,1000) == 0
%         fprintf('%d\n',idx)
%     end
%     tree = mtree(files{idx},'-file');
%     if ~tree.isempty
%         str = tree.tree2str;
%         newNumLines = numel(regexp(str,newline));
%         numLines = numLines + newNumLines;
%         if ismember(files{idx},filesInClosure)
%             numLinesInClosure = numLinesInClosure + newNumLines;
%         end
%     end
% end

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
