%% getProjectFolder
% Returns the full path of the folder sitting inside any folder named
% MinedGithubProjects or OptimizedGithubProjects that is a parent folder of
% the file name provided as input argument
%
% Example:
% file = 'rootFolder\MinedGithubProjects\parentFolder\subfolder1\subfolder2\fileName.m'
% res = getProjectFolder(file);
% res: 'rootFolder\MinedGithubProjects\parentFolder'

function project = getProjectFolder(file)
project = regexp(file,['.*(Min|Optimiz)edGithubProjects\',filesep,'.*?(?=\',filesep,')'],'match','once');
end
