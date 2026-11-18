%% initialize experiment

n = 1e5;
cell1 = num2cell(rand(1,n));
chars = [char(97:122),char(65:90)];
cell2 = cell(size(cell1));
for idx = 1:n
    IDX = randi(numel(chars),1,20);
    cell2{idx} = chars(IDX);
end

benchmarkA = @()extractCells(cell1,cell2);
benchmarkB = @()concatenateCells(cell1,cell2);
