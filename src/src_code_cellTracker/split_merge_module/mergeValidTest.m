function validFlag = mergeValidTest(root_node, bases, movieInfo, refine_res, g)
% test if we should merge the two regions if a0+b0->a1+b1->c
% if a0->a1+b1->a2 is also good, highly likely we should merge
% NOTE: only adjacent frames are considered
validFlag = false;
root_f = movieInfo.frames(root_node);
base_f = movieInfo.frames(bases(1));
if base_f > root_f
    kid_flag = true;
else
    kid_flag = false;
end

root_node2 = nan;
loopCnt = 1;
while loopCnt < g.trackLength4var % if the length is already enough to be a valid track, break;
    bases = unique(bases);
    loopCnt = loopCnt + 1;
    if kid_flag
        pk1 = movieInfo.kids{bases(1)};
        pk2 = movieInfo.kids{bases(2)};
    else
        pk1 = movieInfo.parents{bases(1)};
        pk2 = movieInfo.parents{bases(2)};
    end
    next_bases = [pk1(:); pk2(:)];
    if kid_flag
        one2one_test = cellfun(@length, movieInfo.parents(next_bases));
    else
        one2one_test = cellfun(@length, movieInfo.kids(next_bases));
    end

    if length(pk1) <= 1 && length(pk2) <= 1
        if length(unique(next_bases)) == 2 && isempty(find(one2one_test>1,1))
            bases = next_bases;
            continue;
        elseif length(unique(next_bases)) == 1
            root_node2 = unique(next_bases); % one element or empty
            if kid_flag
                bases = cat(1, bases, movieInfo.parents{root_node2});
            else
                bases = cat(1, bases, movieInfo.kids{root_node2});
            end
            break;
        elseif isempty(unique(next_bases))
            root_node2 = []; % one element or empty
            break;
        end
    else
        return;
    end
end

if isnan(root_node2)% the length of both branches is already enough to be a valid track
    return;
end
if isempty(root_node2)
    validFlag = true;
else
    bases = unique(bases);
    merged_voxIdx = cat(1, movieInfo.voxIdx{bases});
    frames = [movieInfo.frames(root_node2), movieInfo.frames(bases(1))];

    maxCost = voxIdx2cost(movieInfo.voxIdx{root_node2}, merged_voxIdx, ...
        frames, movieInfo, refine_res);
    if maxCost < g.c_ex
        validFlag = true;
    end
end
