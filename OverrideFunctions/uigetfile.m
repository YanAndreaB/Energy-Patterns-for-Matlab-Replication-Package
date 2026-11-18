%% uigetfile

function uigetfile(varargin)
if isscalar(dbstack) % interactive call of clc (in command window)
    evalin('base',sprintf('builtin(''uigetfile'')'))
end
end
