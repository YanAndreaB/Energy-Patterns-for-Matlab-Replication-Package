
function logicalIndexing(arrayCollection,idxCollection)
for idx = 1:numel(arrayCollection)
    A = arrayCollection{idx};
    IDX = idxCollection{idx};
    B = A(IDX);
end
end
