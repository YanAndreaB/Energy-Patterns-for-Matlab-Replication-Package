%% PatternStatisticsTable

classdef PatternStatisticsTable
    properties
        patternDict
        totalNumFiles
        table = table
        names
        snippets
        numPatterns
        numFiles
        patternsPerFile
        numFilesPercentage
    end

    methods
        function obj = PatternStatisticsTable(stat,totalNumFiles)
            [~,checkIds,snippets] = patternInfo;
            obj.patternDict = dictionary(string(checkIds),string(snippets));

            obj.totalNumFiles = totalNumFiles;
            
            checkIds = [stat.checkId]';
            obj.snippets = obj.patternDict(checkIds);
            obj.names = checkIds;
            
            for idx = 1:numel(checkIds)
                IDX = [stat.checkId] == checkIds(idx);
                obj.numPatterns(idx,1) = stat(IDX).numPatterns;
                obj.numFiles(idx,1) = stat(IDX).numFiles;
                obj.patternsPerFile(idx,1) = obj.numPatterns(idx) / obj.numFiles(idx);
            end

            obj.numFilesPercentage = obj.numFiles / obj.totalNumFiles;

            obj.table.names = obj.names;
            obj.table.snippets = obj.snippets;
            obj.table.numPatterns = obj.numPatterns;
            obj.table.numFiles = obj.numFiles;
            obj.table.patternsPerFile = obj.patternsPerFile;
            obj.table.numFilesPercentage = obj.numFilesPercentage;
            obj.table = sortrows(obj.table,'numPatterns','descend');
        end

        function disp(obj)
            fprintf('%s:\n\n',class(obj))
            disp(obj.table)
        end
    end
end
