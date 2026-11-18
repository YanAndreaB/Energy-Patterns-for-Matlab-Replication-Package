%% uiputfile

function uiputfile(varargin)
if isscalar(dbstack) % interactive call of clc (in command window)
    evalin('base',sprintf('builtin(''uiputfile'')'))
end
end
