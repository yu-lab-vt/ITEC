function out = verifyInData(yxz, sz_yxz)

valid_ind = true(size(yxz, 1), 1);
for i=1:size(yxz)
    if ~isempty(find(yxz(i, :)<1, 1)) || ~isempty(find(yxz(i, :)>sz_yxz, 1))
        valid_ind(i) = false;
    end
end

out = yxz(valid_ind,:);