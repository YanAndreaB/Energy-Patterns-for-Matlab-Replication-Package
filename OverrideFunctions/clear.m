%% clear
% The intention to override the built-in clear function is that during
% energy measurement experiments the workspace of the energy test class
% should not get cleared because needed help variables might get cleared as
% well.

function clear(varargin)
if isscalar(dbstack) % interactive call of clear (in command window)
    if isempty(varargin)
        evalin('base',sprintf('builtin(''clear'')'))
    else
        for idx = 1:numel(varargin)
            evalin('base',sprintf('builtin(''clear'',''%s'')',varargin{idx}))
        end
    end
else % clear from within a function or script
    for idx = 1:numel(varargin)
        switch varargin{idx}
            case {'all','variables','classes'} % do nothing
            otherwise % ok, clear single variables
                evalin('caller',sprintf('builtin(''clear'',''%s'')',varargin{idx}))
        end
    end
end
end
