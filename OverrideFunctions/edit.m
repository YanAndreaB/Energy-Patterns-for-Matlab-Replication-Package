%% edit

function edit(fileName,varargin)
if isscalar(dbstack) % interactive call of clc (in command window)
    fileName = which(fileName);
    oldPath = pwd;
    cd(fullfile(matlabroot,'toolbox','matlab','codetools'))
    edit(fileName)
    cd(oldPath)
end
end
