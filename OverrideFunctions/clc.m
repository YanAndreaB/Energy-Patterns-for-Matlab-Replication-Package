%% clc

function clc(varargin)
if isscalar(dbstack) % interactive call of clc (in command window)
    evalin('base',sprintf('builtin(''clc'')'))
elseif ~isempty(varargin) && strcmp(varargin{1},'force')
    evalin('base',sprintf('builtin(''clc'')'))
end
end
