%% prepareProject

function prepareProject(project,rootFolder)
cleanUpRunningProject(rootFolder)
folder = runningProjectFolder(rootFolder);

[~,name] = fileparts(project);
projectFolder = fullfile(folder,name);
mkdir(projectFolder)
copyfile(project,projectFolder)

addpath(genpath(projectFolder))
cd(projectFolder)
end
