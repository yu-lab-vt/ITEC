function [flag, maxCost1, maxCost2] = multiParentsKidsValidLinkTest(append_idx, ...
    append_frame, parent_kid_vec, pk_costs, movieInfo, refine_res, g)
% test scenario 7: a1+b1->a2+b2_half and miss->b3.

parent_kid_vec(parent_kid_vec>length(movieInfo.xCoord)) = nan;
maxCost1 = inf;
maxCost2 = inf;
if isnan(parent_kid_vec(1)) || isnan(parent_kid_vec(2))
    %warning('Input should have one parent and kid!');
    flag = 0;
    return;
end

kid = movieInfo.kids{parent_kid_vec(1)};
parent = movieInfo.parents{parent_kid_vec(2)};
% do not consider cell relations from newly added cells to make it less
% complex; the same as line 5
kid(kid>length(movieInfo.xCoord)) = [];
parent(parent>length(movieInfo.xCoord)) = [];

if length(kid) + length(parent)~=1 % only on of them is non-empty
    flag = 0;
    return;
end
if ~isempty(kid) %a1+b1->a2+b2_half and miss->b3.
    p2cur_cost = movieInfo.Cij{parent_kid_vec(1)}(movieInfo.nei{parent_kid_vec(1)}==kid);
    k_f = movieInfo.frames(parent_kid_vec(2));

    valid_nei_idx = find(movieInfo.frames(movieInfo.nei{kid})==k_f);
    if p2cur_cost > pk_costs(1) && length(valid_nei_idx)>1
        maxCost1 = 0;
        [~,ods] = maxk(movieInfo.ovSize{kid}(valid_nei_idx), 2);
        valid_nei = movieInfo.nei{kid}(valid_nei_idx(ods));
        valid_nei(valid_nei==parent_kid_vec(2)) = [];
        if length(valid_nei) < 1
            keyboard;
            error('duplicate neighbors');
        end
        valid_nei = valid_nei(1);
        frames = [k_f, append_frame];
        [maxCost2, ~] = voxIdx2cost(cat(1, movieInfo.voxIdx{[valid_nei, parent_kid_vec(2)]}), ...
            append_idx, frames, movieInfo, size(refine_res{1}));
    end
else
    cur2k_cost = movieInfo.Cji{parent_kid_vec(2)}(movieInfo.preNei{parent_kid_vec(2)}==parent);
    p_f = movieInfo.frames(parent_kid_vec(1));
    valid_nei_idx = find(movieInfo.frames(movieInfo.preNei{parent})==p_f);
    if cur2k_cost > pk_costs(2) && length(valid_nei_idx)>1
        maxCost2 = 0;
        [~,ods] = maxk(movieInfo.preOvSize{parent}(valid_nei_idx), 2);
        valid_nei = movieInfo.preNei{parent}(valid_nei_idx(ods));
        valid_nei(valid_nei==parent_kid_vec(1)) = [];
        
        if length(valid_nei) < 1
            keyboard;
            error('duplicate neighbors');
        end
        valid_nei = valid_nei(1);
        frames = [p_f, append_frame];
        [maxCost1, ~] = voxIdx2cost(cat(1, movieInfo.voxIdx{[valid_nei, parent_kid_vec(1)]}), ...
            append_idx, frames, movieInfo, size(refine_res{1}));
    end
end
if max([maxCost1, maxCost2]) < abs(g.observationCost)
    flag = true;
else
    flag = false;
end

end