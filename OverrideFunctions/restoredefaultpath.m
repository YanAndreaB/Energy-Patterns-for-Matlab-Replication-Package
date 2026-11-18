
function restoredefaultpath(varargin)
if ~isempty(varargin) && strcmp(varargin{1},'force')
    run(fullfile(matlabroot,'toolbox','local','restoredefaultpath.m'))
end
end
