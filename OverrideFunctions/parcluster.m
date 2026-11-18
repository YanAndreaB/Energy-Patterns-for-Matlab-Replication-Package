%% parcluster

function parcluster(varargin)
if isscalar(dbstack) % interactive call of clc (in command window)
    evalin('base',sprintf('builtin(''parcluster'')'))
end
end
