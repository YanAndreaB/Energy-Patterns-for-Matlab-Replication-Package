%% EnergyTestStudy2

%% 1. Set Folders
rootFolder = projectRoot;

folderStudy2 = fullfile(rootFolder,'Study2');
folderStudy3 = fullfile(rootFolder,'Study3');
folderGithubProjects = fullfile(rootFolder,'GithubProjects');
folderMinedProjects = fullfile(folderGithubProjects,'MinedGithubProjects');

cd(folderStudy2)

%% 2. Find patterns with checkcode
% The file diaryAllWarnings.txt is used to store all instances of code
% analyzer warnings found in the files

diaryFolder = fullfile(folderStudy2,'diaries');
diaryName = fullfile(diaryFolder,'diaryAllWarnings.txt');
% check-ids
[~,warningId] = patternInfo;
% open the diary file
fileID = fopen(diaryName,'W');
fprintf(fileID,'Line ID File\n');

% loop over files
fileNames = mFilesInFolder(folderMinedProjects);
for idx = 1:numel(fileNames)
    % file information
    info = checkcode(fileNames{idx},'-id');
    ids = {info.id};
    % loop over check-ids
    for idx0 = 1:numel(warningId)
        IDX = cellfun(@(arg)strcmp(arg,warningId{idx0}),ids);
        if any(IDX)
            lines = [info(IDX).line];
            ids = {info(IDX).id};

            % loop over single instances of code analyzer warnings
            for idx1 = 1:numel(ids)
                fprintf(fileID,['%d %s "',replace(fileNames{idx},'\','\\'),'"\n'],lines(idx1),ids{idx1});
            end
        end
    end
end

% close the diary file
fclose(fileID);

%% 3. Pattern Statistics
diaryFolder = fullfile(folderStudy2,'diaries');
diaryName = fullfile(diaryFolder,'diaryAllWarnings.txt');
% read data from diary file
data = readtable(diaryName);
[patternNames,warningId,~] = patternInfo;
fileNames = mFilesInFolder(folderMinedProjects);

% loop over check-ids
for idx = 1:numel(warningId)
    % create statistics per check-id
    stats(idx) = PatternStatistics(patternNames{idx},warningId{idx},data); %#ok<SAGROW>
end

% pattern statistics table for selected projects
totalNumFiles = numel(fileNames);
% aggregated statistics table
statTable = PatternStatisticsTable(sort(stats,1,'descend'),totalNumFiles);

%% 4. Files in Static Closure

% load files
load(fullfile(folderStudy3,'filesStudy3.mat'),'filesStudy3')

fileNames = filesStudy3.fileName;
filesInStaticClosure = {};
% loop over files
for idx = 1:numel(fileNames)
    fileName = fileNames{idx};

    % add project folder to matlab path
    projectFolder = getProjectFolder(fileName);
    addpath(genpath(projectFolder))

    % find files in static closure
    files = fileOrbit(fileName);
    filesInStaticClosure = [filesInStaticClosure;files]; %#ok<AGROW>

    % remove project folder from matlab path
    rmpath(genpath(projectFolder))
end
filesInStaticClosure = unique(filesInStaticClosure);
save(fullfile(folderStudy2,'filesInStaticClosure.mat'),'filesInStaticClosure')

%% 5. Warnings in Static Closure

% load files
load(fullfile(folderStudy2,'filesInStaticClosure.mat'),'filesInStaticClosure')

% data about all files in repositories
data = readtable(diaryName);
% intersection of files that exhibit a pattern at all and files in static
% closure
[~,ia,~] = intersect(data.File,filesInStaticClosure);
dataStaticClosure = data(ia,:);

%% 6. Statistics of Static Closure
[patternNames,warningId,msg] = patternInfo;
fileNames = mFilesInFolder(filesInStaticClosure);

% loop over check-ids
for idx = 1:numel(warningId)
    % create statistics per check-id
    statsStaticClosure(idx) = PatternStatistics(patternNames{idx},warningId{idx},dataStaticClosure); %#ok<SAGROW>
end

% pattern statistics table for selected projects
totalNumFilesStaticClosure = numel(filesInStaticClosure);
statTableStaticClosure = PatternStatisticsTable(sort(statsStaticClosure,1,'descend'),totalNumFilesStaticClosure);
