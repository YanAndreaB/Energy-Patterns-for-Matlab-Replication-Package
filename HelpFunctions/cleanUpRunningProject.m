%% cleanUpProject

function cleanUpRunningProject(gitHubSearchFolder)
folder = runningProjectFolder(gitHubSearchFolder);
warning off MATLAB:rmpath:DirNotFound
rmpath(genpath(folder))
warning on MATLAB:rmpath:DirNotFound

oldProject = dir(folder);
oldProject = oldProject(3:end); % cut off . and .. folders
oldProject = arrayfun(@(arg)fullfile(arg.folder,arg.name),oldProject,'UniformOutput',false);
cd(folder)
for idx = 1:numel(oldProject)
    if isfolder(oldProject{idx})
        rmdir(oldProject{idx},'s')
    else
        delete(oldProject{idx})
    end
end
end
