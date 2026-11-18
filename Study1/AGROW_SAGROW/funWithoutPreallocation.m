
function funWithoutPreallocation(n,values)
len = numel(values);
for idx = 1:n
    vec = [];
    for idx1 = 1:len
        vec(idx1) = values(idx1);
    end
end
end
