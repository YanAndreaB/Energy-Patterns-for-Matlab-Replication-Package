%% FilteredPatternStatistics

classdef FilteredPatternStatistics < PatternStatistics
    methods
        function obj = FilteredPatternStatistics(name,fileName,opts,projects,rootFolder)
            obj@PatternStatistics(name,fileName,opts)

            projects = unique(projects);
            fileNames = obj.table.File;
            fileNames = replace(fileNames,[rootFolder,filesep],'');
            extractedProjects = regexp(fileNames,'.*?(?=\\)','match','once');
            res = cellfun(@(arg)ismember(arg,projects),extractedProjects);
            obj.table = obj.table(res,:);
        end
    end
end
