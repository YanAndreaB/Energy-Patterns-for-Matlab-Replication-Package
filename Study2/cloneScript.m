%% Import data
rootFolder = projectRoot;
folderMinedProjects = fullfile(rootFolder,'GithubProjects','MinedGithubProjects');

cd(fullfile(rootFolder,'Study2'))
load csv_import.mat rawData
githubUserName = rawData.githubUserName;
repoName = rawData.repoName;

%% Clone repositories
cd(folderMinedProjects)
urlFun = @(name)fullfile('https://github.com/',char(name));
failedRepos = [];
for idx = 1:height(rawData)
    url = urlFun(rawData.name(idx));
    try
        system(['git clone ',url]);
        movefile(rawData.repoName(idx),rawData.uniqueRepoName(idx))
    catch
        failedRepos = [failedRepos,idx]; %#ok<AGROW>
    end
end
