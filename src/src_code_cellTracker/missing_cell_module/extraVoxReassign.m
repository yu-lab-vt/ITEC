function newLabel = extraVoxReassign(newLabel, fg)
% in the foreground, there are some voxels have not been assigned to a seed
% region in newLabel, we will assign them by distances
z = size(newLabel, 3);
%idx = cell(z, 1);
for i=1:z                                                                   % assign on 2d firstly
    tmp_l = newLabel(:,:,i);
    tmp_fg = fg(:,:,i);
    [l, n] = bwlabel(tmp_fg, 8);
    if n>1                                                                  % remove fg 2d components who doesn't contain labels
        valid_reg = zeros(n, 1);
        s = regionprops(l, 'PixelIdxList');
        for j=1:n                                                           
            if ~isempty(find(tmp_l(s(j).PixelIdxList)>0, 1))
                valid_reg(j) = 1;
            end
        end
        if sum(valid_reg) < n
            tmp_fg = ismember(l, find(valid_reg));
        end
    end
    if ~isempty(find(tmp_l>0, 1)) && n>0                                    % assign unlabeled regions
        [~,idx] = bwdist(tmp_l);
        unassigned = tmp_fg & (tmp_l==0);
        tmp_l(unassigned) = tmp_l(idx(unassigned));
        newLabel(:,:,i) = tmp_l;
    end
end
if ~isempty(find(fg & (newLabel==0), 1))                                    % then assign on 3d case
    [~,idx] = bwdist(newLabel);
    newLabel(fg & (newLabel==0)) = newLabel(idx(fg & (newLabel==0)));
end

end