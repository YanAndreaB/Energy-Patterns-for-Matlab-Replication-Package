%% Start Script
% Sets folder variables and adds needed folders to Matlab search path.

reposFolder = 'C:\GitHub'; % put your folder here where you have your git repos
rootFolder = fullfile(reposFolder,'Energy-Patterns-for-Matlab-Replication-Package');

pathToEnergyTools = fullfile(rootFolder,'energy-tools');
pathToMatlabTools = fullfile(rootFolder,'general-matlab-files');
pathToGeneralMatlabFiles = fullfile(rootFolder,'matlab-tools');
folderMatfiles = fullfile(rootFolder,'MatFiles');
folderHelpfunctions = fullfile(rootFolder,'HelpFunctions');

% restore default path
restoredefaultpath

addpath(rootFolder); % only add folder without sub-folders

% matlab tools, general matlab files, energy tools
addpath(genpath(pathToEnergyTools))
addpath(genpath(pathToMatlabTools))
addpath(genpath(pathToGeneralMatlabFiles))
addpath(genpath(folderMatfiles))
addpath(genpath(folderHelpfunctions))
