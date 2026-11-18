%% tickeTocke
% Author: jan-andrea.bard@unibe.ch
% File Dependencies:
% - MsrRegisters.m
% Other Dependencies
% - Intel CPU (newer than Sandy Bridge)
% - Linux OS
% 
% tickeTocke is used in ticke and tocke. It handles the access to MSR
% registers via MsrRegisters.
% 
% Syntax:
% tickeTocke("initialize")
% counter = tickeTocke("measure");
% [varargout{1:nargout}] = tickeTocke("measure",varargin{:});

function varargout = tickeTocke(type,varargin)
% tickeTocke is used by both ticke and tocke functions

persistent lastEnergyCounterStamp lastDramEnergyCounterStamp energyUnits

switch type
    case "initialize"
        if isempty(energyUnits)
            energyUnits = MsrRegisters.energyUnits;
        end

        % set last energy stamp
        [lastEnergyCounterStamp,lastDramEnergyCounterStamp] = measure;
    case "measure"

        % measure energy
        [currentEnergyCounterStamp,currentDramEnergyCounterStamp] = measure;
        energyCounterDelta = currentEnergyCounterStamp - lastEnergyCounterStamp;
        dramEnergyCounterDelta = currentDramEnergyCounterStamp - lastDramEnergyCounterStamp;

        % calculate consumed energy
        energyDelta = energyCounterDelta * energyUnits;
        dramEnergyDelta = dramEnergyCounterDelta * energyUnits;

        % print to command window
        fprintf('Consumed energy (total CPUs) is %.2f Joules (DRAM: %.2f Joules)\n',energyDelta,dramEnergyDelta)

        if nargout
            varargout = {energyDelta,dramEnergyDelta};
        end
end
end

function [packageEnergy,dramEnergy] = measure
% measure current energy counter stamp

% persistent numCpus
% 
% if isempty(numCpus)
%     numCpus = MsrRegisters.numCpus;
% end

% package
counter = MsrRegisters.energyCounter;
packageEnergy = sum(counter);

% dram
counter = MsrRegisters.dramEnergyCounter;
dramEnergy = sum(counter);
end
