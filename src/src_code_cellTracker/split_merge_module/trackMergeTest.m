function [res_vec, node_inconsistent] = trackMergeTest(cur_track_id, movieInfo, refine_res, ...
    vidMap, g, eigMaps, q, disp_flag)
% test if the >1 trajectories should be merged
%INPUT:
% cur_track_id: id of tested track in movieInfo.tracks
% movieInfo: information of tracks and cells
% label_maps: the 26-connection labelled regions
%OUTPUT:
% res_vec: a vector with two columns, column one is the element ids that 
% need to process, column two is the processing class:
% 1: merge the current node's parents
% 2: merge the current node's kids
% 3: separate the current node based on its parents
% 4: separate the current node based on its kids
% contact: ccwang@vt.edu
if nargin == 7
    disp_flag = false;
end
merge_parents = 1;
merge_kids = 2;
sep_by_parents = 3;
sep_by_kids = 4;
% for each multiple-to-one or one-to-mulitiple node, build a tree
cur_track = movieInfo.tracks{cur_track_id}';
cur_parents = movieInfo.parents(cur_track);
cur_kids = movieInfo.kids(cur_track);
%ff = [movieInfo.frames(cur_track), cur_track];
one2multi = cur_track(cellfun(@length, cur_kids)>1);
p_k_consistency = zeros(length(one2multi), 1);
pk_handle = nan(length(one2multi), 1);
node_inconsistent = []; % for inconsistent parents and kids, we must merge them, otherwise will cause dilemma
% res_cell_o2m = cell(length(one2multi), 1);
res_vec_o2m = zeros(length(one2multi), 3);
dir_idx = 2; % both directions (left and right)
node4merge = [];
o2m_flag = true;
for i=1:length(one2multi)
    root_node = one2multi(i);
    if ~isempty(find(node4merge == root_node, 1))
        % the node has already been decided to merge with other node
        % which means this region is not a properiate region, thus shoul
        % not be used as an reference
        continue;
    end
    p_k_consistency(i) = parentsKidsConsistency(root_node, movieInfo, ...
        refine_res, g);
    if p_k_consistency(i) == 0
        pk_handle(i) = handleInconsistentParentKid(root_node, movieInfo, refine_res, ...
            vidMap, eigMaps, q, g);
        if ~isnan(pk_handle(i))
            if pk_handle(i) == 1% merge parents and kids
                k1 = movieInfo.kids{root_node}(1);
                k2 = movieInfo.kids{root_node}(2);
                f2 = regionAdjacent(movieInfo, refine_res, k1, k2);
                if f2
                    % if these two kids are adjacent
                    res_vec_o2m(i,:) = [root_node, merge_kids, 1];
                    node_inconsistent = cat(1, node_inconsistent, [k1,k2]);
                    node4merge = cat(1, node4merge, movieInfo.kids{root_node}); % no need indeed
                else
                    % if these two kids are not adjacent, we should not merge
                    % them even though parents/kids are not consisitent; it is
                    % possible the problem is from parents
                    res_vec_o2m(i,:) = [root_node, merge_kids, 0]; % NOTE: 0 will be removed
                end
            else % sep_by_parents or sep_by_kids
                res_vec_o2m(i,:) = [root_node, pk_handle(i), 1];
            end
        end
    else
        [one_cell_flag, pValue, mergeVSseg] = treeBuild(root_node, ...
            cur_track_id, movieInfo, refine_res, vidMap, g, dir_idx, ...
            eigMaps, q, o2m_flag);
        if one_cell_flag == 1
            cell_num = 1;
            res_vec_o2m(i,:) = [root_node, merge_kids, pValue];
            node4merge = cat(1, node4merge, movieInfo.kids{root_node});
        elseif one_cell_flag == 0 % only this case, we separate the one region in to two
            cell_num = 2;
            res_vec_o2m(i,:) = [root_node, sep_by_kids, pValue];
        else
            cell_num = nan;
        end
        if disp_flag
            fprintf('one2multiple at frame %d->%d, estimate #cell:%d with voting: %d -vs- %d\n',...
                movieInfo.frames(root_node), movieInfo.frames(movieInfo.kids{root_node}(1)),...
                cell_num, mergeVSseg(1), mergeVSseg(2));
        end
    end

end

multi2one = cur_track(cellfun(@length, cur_parents)>1);% check duplicate
% eleCommon = intersect(multi2one, one2multi);
% multi2one = setxor(multi2one,eleCommon);
res_vec_m2o = zeros(length(multi2one), 3);
node4split = cat(1, movieInfo.kids{node4merge});
o2m_flag = false;
for i=1:length(multi2one)
    root_node = multi2one(i);
    if ~isempty(find(node4split == root_node, 1))
        % the node is a kid of a region that has been decided to split or
        % merge with another region
        % thus should not be test any more
        continue;
    end
    % handle repeated elements; 
    % only two cases will duplicate: 2->1->2 and 1->2->1 
    repeat_loc = find(res_vec_o2m(:,1)==root_node,1);
    if ~isempty(repeat_loc)
        if p_k_consistency(repeat_loc) == 0
            if ~isnan(pk_handle(repeat_loc))
                if pk_handle(repeat_loc) == 1% merge parents and kids
                    f2 = regionAdjacent(movieInfo, refine_res, ....
                        movieInfo.parents{root_node}(1), ...
                        movieInfo.parents{root_node}(2));
                    if f2 % the two parents are adjacent
                        % if these two parents are adjacent
                        res_vec_m2o(i,:) = [root_node, merge_parents, 1];
                        node_inconsistent = cat(1, node_inconsistent, movieInfo.parents{root_node}');
                    else
                        % if these two parents are not adjacent, we should not merge
                        % them even though parents/kids are not consisitent; it is
                        % possible the problem is from kids
                        res_vec_m2o(i,:) = [root_node, merge_parents, 0]; % NOTE: 0 will be removed
                    end
                %else % other cases has been processed in one2multiple cases
                end
            end
            continue;
        elseif res_vec_o2m(repeat_loc,2) == sep_by_kids
            node4split = cat(1, node4split, movieInfo.kids{root_node}); % no need indeed
            continue;
        end
    end
    repeat_parent = movieInfo.parents{movieInfo.parents{root_node}(1)};
    if length(repeat_parent)==1
        repeat_loc = find(res_vec_o2m(:,1)==repeat_parent,1);
        if ~isempty(repeat_loc)
            if res_vec_o2m(repeat_loc,2) == merge_kids
                continue;
            end
        end
    end
    % right
    [one_cell_flag, pValue, mergeVSseg] = treeBuild(root_node, ...
        cur_track_id, movieInfo, refine_res, vidMap, g, dir_idx, ...
        eigMaps, q, o2m_flag);
    if one_cell_flag == 1
        cell_num = 1;
        res_vec_m2o(i,:) = [root_node, merge_parents, pValue];
    elseif one_cell_flag == 0
        cell_num = 2;
        node4split = cat(1, node4split, movieInfo.kids{root_node});
        res_vec_m2o(i,:) = [root_node, sep_by_parents, pValue];
    else
        cell_num = nan;
    end
    if disp_flag
        fprintf('multi2one at frame %d->%d, estimate #cell:%d with voting: %d -vs- %d\n',...
            movieInfo.frames(movieInfo.parents{root_node}(1)),movieInfo.frames(root_node),...
            cell_num, mergeVSseg(1), mergeVSseg(2));
    end
end
res_vec_o2m = res_vec_o2m(res_vec_o2m(:,3)~=0, :);
res_vec_m2o = res_vec_m2o(res_vec_m2o(:,3)~=0, :);

res_vec = cat(1, res_vec_o2m, res_vec_m2o);
[~,ia] = unique(res_vec(:,1:2),'rows');
res_vec = res_vec(ia,:);

node_inconsistent = unique(node_inconsistent, 'rows'); % nodes must merge