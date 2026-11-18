%% initialize experiment

n = 2.5e3;
len = 10000;
values = rand(1,len);

benchmarkA = @()funWithoutPreallocation(n,values); % probably worse alternative
benchmarkB = @()funWithPreallocation(n,values); % probably better alternative
