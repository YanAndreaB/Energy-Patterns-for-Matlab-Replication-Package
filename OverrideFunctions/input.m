%% input

function input(varargin)
if isscalar(dbstack) % interactive call of clc (in command window)
    evalin('base',sprintf('builtin(''input'')'))
end
end
