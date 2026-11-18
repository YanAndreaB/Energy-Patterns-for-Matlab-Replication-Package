%% initialize experiment

n = 3e6;
S.f1 = 0;

benchmarkA = @()useGetfield(S,n); % probably worse alternative
benchmarkB = @()useDotNotation(S,n); % probably better alternative
