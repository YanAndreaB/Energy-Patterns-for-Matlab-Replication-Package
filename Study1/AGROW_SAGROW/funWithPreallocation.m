
function funWithPreallocation(n,values)
len = numel(values);
for idx = 1:n
    vec = zeros(1,len);
    for idx1 = 1:len
        vec(idx1) = values(idx1);
    end
end
end
