%% uigetdir

function uigetdir(varargin)
if isscalar(dbstack) % interactive call of clc (in command window)
    evalin('base',sprintf('builtin(''uigetdir'')'))
end
end
