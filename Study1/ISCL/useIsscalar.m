
function useIsscalar(mat,n)
for idx0 = 1:n
    for idx = 1:numel(mat)
        B2 = isscalar(mat{idx});
    end
end
end
