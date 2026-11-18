%% EnergyTestStudy1

%% 1. Set Folders
rootFolder = projectRoot;
folderStudy1 = fullfile(rootFolder,'Study1');

currentPath = pwd;
cd(folderStudy1)

%% 2. Initialize variables
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

cd(currentPath)
