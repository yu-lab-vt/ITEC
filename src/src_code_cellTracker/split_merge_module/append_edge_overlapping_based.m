function [edge_cost, ovNeighbors] = append_edge_overlapping_based...
    (adj_nei, adj_ov, adj_fr, cur_node, movieInfo, post_flag, g)
% if there are two regions overlapped with current region with >50%, we
% should allow two edges linked to current region
% INPUT:
%     adj_nei: neighbors in nearby frames
%     adj_ov: overlapping vox length of neighbors
%     adj_fr: frame number of neighbors
%     cur_node: current node in consideration
%     movieInfo: infor about all nodes
%     post_flag: true means we are processing sucessor nodes compared with
%     cur_node (otherwise, we are processing predecessor nodes)
%     limit_flag: we set a limit to the largest reward
% OUTPUT:
%     edge_cost: cost of the edge if we decide to add one
%     ovNeighbors: the neighbors might be merged

if nargin == 5
    post_flag = false;
    obz_reward = inf;
elseif nargin == 6
    obz_reward = inf;
else
    obz_reward = -g.observationCost;
end
edge_cost = [];
ovNeighbors = [];
if length(adj_nei)<2
    return;
end
curRegVox = movieInfo.vox{cur_node};
% nodes with smallest Distance (previously ,we use largest overlapping ratio)
best_dirwiseDist_node = zeros(length(adj_nei),1); 
best_dirwiseDist_node_min_Cost = zeros(length(adj_nei),2);
cur_fr = movieInfo.frames(cur_node);
for i=1:length(adj_nei)
    if post_flag % see post-neighbors' pre-overlapping region
        neis = movieInfo.preNei{adj_nei(i)};
        cur_locs = find(movieInfo.frames(neis)==cur_fr);
        [~, loc] = min(movieInfo.CDist_j2i{adj_nei(i)}(cur_locs));
        best_dirwiseDist_node(i) = neis(cur_locs(loc));
        if neis(cur_locs(loc)) == cur_node
            cur_locs(loc) = [];
        end
        if ~isempty(cur_locs)
            [val, loc] = min(movieInfo.Cji{adj_nei(i)}(cur_locs));
            best_dirwiseDist_node_min_Cost(i,:) = [neis(cur_locs(loc)) val];
        else
            best_dirwiseDist_node_min_Cost(i,:) = [cur_node inf];
        end
    else % see pre-neighbors' post-overlapping region
        neis = movieInfo.nei{adj_nei(i)};
        cur_locs = find(movieInfo.frames(neis)==cur_fr);
        [~, loc] = min(movieInfo.CDist_i2j{adj_nei(i)}(cur_locs,1));
        best_dirwiseDist_node(i) = neis(cur_locs(loc));
        if neis(cur_locs(loc)) == cur_node
            cur_locs(loc) = [];
        end
        if ~isempty(cur_locs)
            [val, loc] = min(movieInfo.Cij{adj_nei(i)}(cur_locs));
            best_dirwiseDist_node_min_Cost(i,:) = [neis(cur_locs(loc)) val];
        else
            best_dirwiseDist_node_min_Cost(i,:) = [cur_node inf];
        end
    end
end
best_dirwiseDist_node_min_Cost(best_dirwiseDist_node_min_Cost(:,1) == cur_node, 2) = inf;
% considerBrokenCellOnly
if isfield(g, 'considerBrokenCellOnly')
    if g.considerBrokenCellOnly
        best_dirwiseDist_node = double(best_dirwiseDist_node==cur_node & ...
                    best_dirwiseDist_node_min_Cost(:, 2) > obz_reward);
    end
end
uni_fr = unique(adj_fr);
if ~post_flag
    uni_fr = uni_fr(end:-1:1);% descending order
end
% we add several other criterion for detecting split/merge
min_cost_change = 0;%movieInfo.arc_avg_mid_std(cur_node, 3);
cost_good2go = min(movieInfo.arc_avg_mid_std(cur_node, 1:2));%sum(movieInfo.arc_avg_mid_std(cur_node, [1,3]));
if cost_good2go > min(g.c_ex,g.c_en) || min_cost_change > min(g.c_ex,g.c_en)
    cost_good2go = 0;
    min_cost_change = 0;
end

for j=1:length(uni_fr)
    nei_this_locs = find(adj_fr==uni_fr(j) & best_dirwiseDist_node);
    nei_thisframe = adj_nei(nei_this_locs);
    
    if length(nei_thisframe)>1
        combinations = nchoosek((1:length(nei_thisframe)), 2);
        max2_idx = combinations(1,:);
        newOvDistance = inf;
        for cc = 1:size(combinations, 1)
            tmp_idx = combinations(cc,:);
            tmp_Vox = cat(1, movieInfo.vox{nei_thisframe(tmp_idx)});
            frame_shift = getNonRigidDrift(curRegVox, tmp_Vox, cur_fr, uni_fr(j), movieInfo.drift, g.driftInfo);
            tmpOvDist = ovDistanceRegion(curRegVox, tmp_Vox, frame_shift);
            if tmpOvDist < newOvDistance
                max2_idx = tmp_idx;
                newOvDistance = tmpOvDist;
            end
        end
        newCost = overlap2cost(newOvDistance, movieInfo.ovGamma, ...
            movieInfo.jumpRatio(abs(uni_fr(j)-cur_fr)));
        if post_flag
            oldCosts = movieInfo.Cij{cur_node}(nei_this_locs(max2_idx));
            min_cost = min(movieInfo.Cij{cur_node});
        else
            oldCosts = movieInfo.Cji{cur_node}(nei_this_locs(max2_idx));
            min_cost = min(movieInfo.Cji{cur_node});
        end
        if newCost < (min_cost-0.001) && min_cost > cost_good2go
            if g.splitMergeCost
                newCost = newCost / 2;
            end
            if newCost < min(g.c_ex,g.c_en) % also need to < enter/exit cost
                ovNeighbors = cat(1, ovNeighbors, nei_thisframe(max2_idx));
                oldCosts(isinf(oldCosts)) = 1000;
                edge_cost = cat(1, edge_cost, zeros(size(oldCosts)) + newCost);%newCost*length(oldCosts)*(oldCosts./sum(oldCosts));
            end
        end
        
    end
    % if there is a feasible nodes in this frame, no need to continue
    if post_flag
        nei_costs = movieInfo.Cij{cur_node};
    else
        nei_costs = movieInfo.Cji{cur_node};
    end
    if ~isempty(find(best_dirwiseDist_node(nei_this_locs) & nei_costs(nei_this_locs)<obz_reward,1))
        break; 
    end
end



end