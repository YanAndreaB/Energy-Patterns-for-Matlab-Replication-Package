%% EnergyTestStudy1

%% 1. Set Folders
disp '1. Set Folders'

rootFolder = projectRoot;
folderStudy1 = fullfile(rootFolder,'Study1');

currentPath = pwd;
cd(folderStudy1)

%% 2. Initialize variables
disp '2. Initialize Variables'

failedMeasurements = [];
folderNames = {
    'AGROW_SAGROW'
    'AND2'
    'CCAT'
    'EXIST'
    'FNDSB'
    'GFLD'
    'ISCL'
    'OR2'
    'ST2NM'
    };
folderNames = cellfun(@(arg)fullfile(folderStudy1,arg),folderNames,'UniformOutput',false);

%% 3. Run experiments
disp '3. Run experiments'

for idx = 1:numel(folderNames)
    cd(folderNames{idx})
    % TestingClass = EnergyTestScript; % real measurement
    TestingClass = EnergyTestRun; % for testing purpose
    try
        disp(['Running ',folderNames{idx}])
        TestingClass.execute
    catch err
        failedMeasurements(end + 1) = idx; %#ok<*SAGROW>
    end
end

%% 4. Create Table
disp '4. Create Table'

cd(folderStudy1)

% search sub-folders of folderStudy1 for mat-files beginning with
% 'measurement' and ending on 'processed'

res = dir('**/*measurement*processed.mat');
fullNames = arrayfun(@(arg)fullfile(arg.folder,arg.name),res,'UniformOutput',false);
patterns = replace(fullNames,folderStudy1,'');
patterns = regexp(patterns,['(?<=\',filesep,').*?(?=\',filesep,')'],'match','once');
rowNames = {'Check-ID','Non-fixed Recommendation','Fixed Recommendation', ...
    'Energy (Time) Gain','Significance','p-Value'};
order = [6,4,1,9,3,5,2,8,7];
fullNames = fullNames(order);
patterns = patterns(order);

infoTable = cell(2 * numel(patterns),numel(rowNames));
for idx = 1:numel(patterns)
    row = TableRow(patterns{idx},fullNames{idx});
    infoTable(2 * idx - 1,:) = split(row.string1,' ')';
    infoTable(2 * idx,:) = split(row.string2,' ')';
end
infoTable = cell2table(infoTable);
infoTable.Properties.VariableNames = rowNames;

writetable(infoTable,'Results_Study_1.csv')
