
function findIndexing(arrayCollection,idxCollection)
for idx = 1:numel(arrayCollection)
    A = arrayCollection{idx};
    IDX = idxCollection{idx};
    B = A(find(IDX));
end
end
