
function res = projectRoot
res = mfilename('fullpath');
res = fileparts(res);
end
