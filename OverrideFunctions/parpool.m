%% parpool

function parpool(varargin)
if isscalar(dbstack) % interactive call of clc (in command window)
    evalin('base',sprintf('builtin(''parpool'')'))
end
end
