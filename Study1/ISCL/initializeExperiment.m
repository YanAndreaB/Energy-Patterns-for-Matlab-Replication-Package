%% initialize experiment

n = 1e6;
repetitions = 30;
for idx = n:-1:1
    len = randi(100);
    mat{idx} = rand(1,len);
end

benchmarkA = @()useLength(mat,repetitions); % probably worse alternative
benchmarkB = @()useIsscalar(mat,repetitions); % probably better alternative
