%% Import data
rootFolder = projectRoot;
folderMinedProjects = fullfile(rootFolder,'GithubProjects','MinedGithubProjects');

cd(fullfile(rootFolder,'Study2'))
load csv_import.mat rawData
githubUserName = rawData.githubUserName;
repoName = rawData.repoName;

%% Clone repositories
urlFun = @(name)fullfile('https://github.com/',char(name));
failedRepos = [];
for idx = 1:height(rawData)
    cd(folderMinedProjects)
    url = urlFun(rawData.name(idx));
    try
        system(['git clone ',url]);
        uniqueRepoName = char(rawData.uniqueRepoName(idx));
        movefile(rawData.repoName(idx),uniqueRepoName)

        cd(uniqueRepoName)
        system(['git config --global --add safe.directory ',fullfile(folderMinedProjects,uniqueRepoName)]);
        system('sudo git reset --hard $(git rev-list -1 --before="2026-05-07" HEAD)')
    catch
        failedRepos = [failedRepos,idx]; %#ok<AGROW>
    end
end
cd(folderMinedProjects)
