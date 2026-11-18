%% echo

function echo(varargin)
if isscalar(dbstack) % interactive call of clc (in command window)
    evalin('base',sprintf('builtin(''echo'')'))
end
end
