%% initialize experiment

varNames = {'myVar','yourVar'};
indices = randi(2,1,25000);
varNames = varNames(indices);

benchmarkA = @()existFun(varNames);
benchmarkB = @()existFunTwoArgs(varNames);
