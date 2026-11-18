%% MsrRegisters
% Author: jan-andrea.bard@unibe.ch
% File Dependencies:
% - readMsrByIdMex_noErrorHandling.mex*
% - readMsrByIdMex_noErrorHandling.c
% Other Dependencies
% - Intel CPU (newer than Sandy Bridge)
% - Linux OS
% 
% MsrRegisters handles the access to MSR registers in connection with the
% RAPL (Running Average Power Limit) interface (on Linux systems with an
% Intel CPU). The file readMsrByIdMex_noErrorHandling.c must be compiled to
% a mex function before its functionality can be used.
% 
% Syntax:
% eCounter = MsrRegisters.energyCounter;
% dramCounter = MsrRegisters.dramEnergyCounter;
% eUnits = MsrRegisters.energyUnits;

classdef MsrRegisters
    properties (Access = public,Constant)
        MSR_RAPL_POWER_UNIT = 0x606; % MSR register for power units
        MSR_PKG_ENERGY_STATUS = 0x611; % MSR register for engergy status
        MSR_DRAM_ENERGY_STATUS = 0x619; % MSR register for DRAM engergy status
        % MAX_ENERGY_RANGE_UJ % TODO: maximum energy range before counter overflows
        fileName_readMsr = fullfile(generalMatlabFilesPath,'ticke-tocke','mex','readMsrById_noErrorHandling')

        % getNumCpusMex counts the directories inside directory /dev/cpu
        % (not counting . and ..)
    end

    % methods
    %     function obj = MsrRegisters
    %         obj.exponentPowerUnits = hex2dec(unitsStr(end-1:end));
    %         obj.exponentTimeUnits = hex2dec(unitsStr(1:end-4));
    %     end
    % end
    properties(Access=public)
       numCpus = 1
    end

    methods
        function obj = MsrRegisters
            % constructor
            switch computer
                case 'GLNXA64'
                    obj.numCpus = getNumCpus;
                otherwise
                    % do nothing
            end
        end
    end

    methods (Static,Access = public)
        function counter = dramEnergyCounter
            % MSR counter for DRAM
            obj = MsrRegisters;
            numCpus = 1;
            for idx = numCpus:-1:1
                counter(idx) = obj.readRegister(obj.MSR_DRAM_ENERGY_STATUS,idx);
            end
        end

        function counter = energyCounter
            % MSR counter for energy
            obj = MsrRegisters;
            numCpus = 1;
            for idx = numCpus:-1:1
                counter(idx) = obj.readRegister(obj.MSR_PKG_ENERGY_STATUS,idx);
            end
        end

        function res = energyUnits
            % energy units
            obj = MsrRegisters;
            cpuId = 0;
            units = obj.readRegister(obj.MSR_RAPL_POWER_UNIT,cpuId);
            unitsStr = dec2hex(units);
            exponentEnergyUnits = hex2dec(unitsStr(end-3:end-2));
            res = 0.5^exponentEnergyUnits;
        end
    end

    methods (Static,Access = private)
        function queryRes = readRegister(registerId,cpuId)
            if isRootUser
                % as root
                queryRes = readMsrByIdMex_noErrorHandling(registerId,cpuId);
            else
                % as non-root
                error('Root-user access rights are needed.')
            end
        end
    end
end