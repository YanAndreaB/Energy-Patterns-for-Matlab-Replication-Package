%% initialize experiment

vec = arrayfun(@num2str,randi(10000,1,1e5),'UniformOutput',false);

benchmarkA = @()useStr2num(vec); % probably worse alternative
benchmarkB = @()useStr2double(vec); % probably better alternative
