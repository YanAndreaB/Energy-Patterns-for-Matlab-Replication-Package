%% TableRow

classdef TableRow < handle
    properties
        energyMedianPair
        timeMedianPair
        ratio_b
        ratio_t
    end

    properties
        rowTitle
    end

    properties (Dependent)
        gain_b
        gain_t
        string1
        string2
        ratioDifference
        gainDifference
    end

    methods
        function obj = TableRow(rowTitle,matFile)
            % constructor
            
            obj.rowTitle = rowTitle;

            obj.energyMedianPair = EnergyMedianPair(obj.rowTitle,matFile);
            obj.timeMedianPair = TimeMedianPair(obj.rowTitle,matFile);
            obj.loadRatios(matFile)
        end

        function val = get.gain_b(obj)
            val = 1 - obj.ratio_b;
        end

        function val = get.gain_t(obj)
            val = 1 - obj.ratio_t;
        end

        function val = get.gainDifference(obj)
            val = obj.gain_b - obj.gain_t;
        end

        function val = get.ratioDifference(obj)
            val = obj.ratio_b - obj.ratio_t;
        end

        function val = get.string1(obj)
            val = obj.energyMedianPair.string;
        end

        function val = get.string2(obj)
            val = obj.timeMedianPair.string;
        end
    end

    methods (Access = private)
        function loadRatios(obj,matFile)
            loadRes = load(matFile,'ratio_b','ratio_t');
            obj.ratio_b = loadRes.ratio_b;
            obj.ratio_t = loadRes.ratio_t;
        end
    end
end
