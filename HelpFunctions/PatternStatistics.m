%% PatternStatistics

classdef PatternStatistics
    properties
        name
        checkId
    end

    properties (Access = private)
        table
    end

    properties (Dependent)
        numPatterns
        numFiles
        patternsPerFile
    end

    methods
        function obj = PatternStatistics(name,checkId,data)
            obj.name = name;
            obj.checkId = string(checkId);

            obj.table = data(data.ID == obj.checkId,:);
        end

        function val = get.numPatterns(obj)
            val = size(obj.table,1);
        end

        function val = get.numFiles(obj)
            val = numel(unique(obj.table.File));
        end

        function val = get.patternsPerFile(obj)
            val = obj.numPatterns / obj.numFiles;
        end

        function objects = sort(objects,type,varargin)
            switch type
                case 1
                    numItems = [objects.numPatterns];
                case 2
                    numItems = [objects.numFiles];
            end
            [~,order] = sort(numItems,varargin{:});
            objects = objects(order);
        end
    end
end
