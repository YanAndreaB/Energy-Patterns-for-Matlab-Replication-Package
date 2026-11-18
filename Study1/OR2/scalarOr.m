
function scalarOr(vec1,vec2,n)
for idx = 1:n
    for idx1 = 1:numel(vec1)
        if numel(vec1{idx1}) || numel(vec2{idx1})
            a = 0;
        end
    end
end
end
