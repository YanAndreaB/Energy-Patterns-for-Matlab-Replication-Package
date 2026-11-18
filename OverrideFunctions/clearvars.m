%% clear
% The intention to override the built-in clear function is that during
% energy measurement experiments the workspace of the energy test class
% should not get cleared because needed help variables might get cleared as
% well.

function clearvars(varargin)
if isscalar(dbstack) % interactive call of clear (in command window)
    if isempty(varargin)
        evalin('base',sprintf('builtin(''clearvars'')'))
    else
        str = "'" + varargin{1} + "'";
        for idx = 2:numel(varargin)
            str = str + ",'" + varargin{idx} + "'";
            evalin('base',sprintf("builtin('clearvars',%s)",str))
        end
    end
else % clear from within a function or script
    if isempty(varargin)
        % do nothing
    else
        for idx = 1:numel(varargin)
            evalin('base',sprintf('builtin(''clearvars'',''%s'')',varargin{idx}))
        end
    end
end
end
