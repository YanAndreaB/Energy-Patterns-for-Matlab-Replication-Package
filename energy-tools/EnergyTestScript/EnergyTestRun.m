%% EnergyTestRun
% EnergyTestRun is used to trigger every benchmark once to check if
% they all run through without erroring. Especially if it is a bulk
% experiment.

classdef EnergyTestRun < EnergyTestScript
    methods
        function obj = EnergyTestRun
            obj.pauseDuration = 0;
            obj.numRepetitions = 1;
        end
    end

    methods (Access = protected)
        function dispLoggedInUsers(varargin)
            % do nothing in test mode
        end
    end
end
