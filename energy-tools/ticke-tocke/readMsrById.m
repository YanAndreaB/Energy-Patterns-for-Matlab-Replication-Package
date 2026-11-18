%% readMsrById

function res = readMsrById(registerId,cpuId)
fileName = fullfile(gitLabPath,'general-matlab-files','ticke-tocke','mex','readMsrById_noErrorHandling');
cmd = [fileName,' ',num2str(registerId),' ',num2str(cpuId)];
[~,res] = system(cmd);
res = str2double(res);
end
