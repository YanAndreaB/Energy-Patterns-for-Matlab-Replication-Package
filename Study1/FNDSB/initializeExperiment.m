%% initialize experiment

n = 1e5;
for idx = 2000:-1:1
    arrayCollection{idx} = rand(1,n);
    idxCollection{idx} = logical(randi(2,1,n) - 1);
end

benchmarkA = @()findIndexing(arrayCollection,idxCollection);
benchmarkB = @()logicalIndexing(arrayCollection,idxCollection);
