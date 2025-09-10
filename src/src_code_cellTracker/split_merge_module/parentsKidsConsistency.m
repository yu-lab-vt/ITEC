function flag = parentsKidsConsistency(test_cell, movieInfo, refine_res, ...
    g)
% test if the parents / kids of test_cell is consistent, if not, merge its
% parents and kids
flag = nan;
p = movieInfo.parents{test_cell};
k = movieInfo.kids{test_cell};
if ~isfield(g, 'par_kid_consistency_check') % do not check
    return;
end
if length(p)~=2 || length(k)~=2 || ~g.par_kid_consistency_check
    return
end

p_voxIdx = cat(1, movieInfo.voxIdx{p});
k_voxIdx = cat(1, movieInfo.voxIdx{k});
frames = [movieInfo.frames(p(1)) movieInfo.frames(k(1))];
[maxCost, ~] = voxIdx2cost(p_voxIdx, ...
        k_voxIdx, frames, movieInfo, size(refine_res{1}));
if maxCost >= abs(g.observationCost)
    return;
end
p_k_costs = inf(2,2);
for i=1:2
    for j=1:2
        d = movieInfo.CDist{p(i)}(movieInfo.nei{p(i)}==k(j));
        if ~isempty(d)
            p_k_costs(i,j) = overlap2cost(d, movieInfo.ovGamma);
%         elseif movieInfo.frames(p(i)) > movieInfo.frames(k(j)) + g.k
%             [maxCost, ~] = voxIdx2cost(p_voxIdx, ...
%         k_voxIdx, frames, movieInfo, size(refine_res{1}));
        end
    end
end
if max(p_k_costs(1,1), p_k_costs(2,2)) < abs(g.observationCost) ||...
        max(p_k_costs(1,2), p_k_costs(2,1)) < abs(g.observationCost)
    flag = 1;
else
    flag = 0;
end
end