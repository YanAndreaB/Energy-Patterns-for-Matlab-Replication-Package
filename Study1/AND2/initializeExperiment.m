%% initialize experiment

numVectors = 1e6;
n = 10;
lengths = [zeros(1,50),1:100];
numLenghts = numel(lengths);
for idx = numVectors:-1:1
    IDX = randi(numLenghts);
    vec1{idx} = rand(1,lengths(IDX));
    IDX = randi(numLenghts);
    vec2{idx} = rand(1,lengths(IDX));
end

benchmarkA = @()vectorAnd(vec1,vec2,n); % probably worse alternative
benchmarkB = @()scalarAnd(vec1,vec2,n); % probably better alternative
