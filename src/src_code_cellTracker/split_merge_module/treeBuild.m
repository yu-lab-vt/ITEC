function [one_cell_flag, oneCellpValue, mergeVSseg] = treeBuild(...
    root_node, track_id, movieInfo, refine_res, vidMap, g, dir_idx,...
    eigMaps, q, o2m_flag)
% build a tree given a root node
% dir_idx:  0: means only build using the decendents of root_node
%           1: means only build using the ancestors of root_node
%           2: build both trees, one forward tree and one backward tree
% NOTE: we need verify we are still working on the same cell(s), if only
% one region exist in a frame; TODO: Do we need to consider continutity?
cur_track = movieInfo.tracks{track_id}';
% right_cnt = [0 0]; % one, >one
% left_tree = {};
% right_tree = {};
if dir_idx==0 || dir_idx == 2
    % right-direction
    tree_nodes = root_node;
    pre_nodes = root_node;
    while true% if there is a frame lose one region, we need to test
        kids = cat(1, movieInfo.kids{pre_nodes});
        if ~isempty(kids)
            tree_nodes = cat(1, tree_nodes, kids);
            pre_nodes = unique(kids);
        else
            break;
        end
    end
    tree_nodes = unique(tree_nodes);
%     tree_nodes = cur_track(cur_track>=root_node);
    %tree_nodes = unique(tree_nodes);% already sorted with ascend order
    tree_frames = movieInfo.frames(tree_nodes);
    freq_cnts = frequency_cnt(tree_frames);
    right_cells = mat2cell(tree_nodes, freq_cnts(:,2),1);
    % test if should remove some levels of the tree
    pre_nodes = root_node;
    for i=2:numel(right_cells)% if there is a frame lose one region, we need to test
        %if length(pre_nodes) ~= length(right_cells{i})
            kids = unique(cat(1, movieInfo.kids{pre_nodes}));
            parents = unique(cat(1, movieInfo.parents{right_cells{i}}));
            if ~vec_equal(kids, right_cells{i}, 1) || ~vec_equal(parents, pre_nodes, 1)
                right_cells = right_cells(1:i-1);
                break;
            end
        %end
        pre_nodes = right_cells{i};
    end
%     freq_cnts = cellfun(@length, right_cells);
%     right_cnt(1) = sum(freq_cnts==1);
%     right_cnt(2) = sum(freq_cnts>1);
%     right_tree = freq_cnts;

end
% left_cnt = [0 0]; % one, >one
if dir_idx==1 || dir_idx == 2
    % left-direction
    tree_nodes = root_node;
    pre_nodes = root_node;
    while true% if there is a frame lose one region, we need to test
        parents = cat(1, movieInfo.parents{pre_nodes});
        if ~isempty(parents)
            tree_nodes = cat(1, tree_nodes, parents);
            pre_nodes = unique(parents);
        else
            break;
        end
    end
    tree_nodes = unique(tree_nodes);
    %tree_nodes = cur_track(cur_track<=root_node);
    tree_frames = movieInfo.frames(tree_nodes);
    freq_cnts = frequency_cnt(tree_frames);
    left_cells = mat2cell(tree_nodes, freq_cnts(:,2),1);
    left_cells = left_cells(end:-1:1); % reverse the cells
    % test if should remove some levels of the tree
    post_nodes = root_node;
    for i=2:numel(left_cells)% if there is a frame lose one region, we need to test
        %if length(post_nodes) ~= length(left_cells{i})
            kids = unique(cat(1, movieInfo.kids{left_cells{i}}));
            parents = unique(cat(1, movieInfo.parents{post_nodes}));
            if ~vec_equal(kids, post_nodes, 1) || ~vec_equal(parents, left_cells{i}, 1)
                left_cells = left_cells(1:i-1);
                break;
            end
        %end
        post_nodes = left_cells{i};
    end
%     freq_cnts = cellfun(@length, left_cells);
%     left_cnt(1) = sum(freq_cnts==1);
%     left_cnt(2) = sum(freq_cnts>1);
%     left_tree = freq_cnts;
end
[one_cell_flag, oneCellpValue, mergeVSseg] = cellNumJudge_gapGuided(...
    left_cells, right_cells, movieInfo, refine_res, vidMap, g, ...
    eigMaps, q, o2m_flag);
% mergeVSseg = left_cnt + right_cnt; % element 1 means one cell, 2 means >1 cells
% mergeVSseg(1) = mergeVSseg(1)-1;% root node was counted twice
% 
% oneCellpValue = binocdf(mergeVSseg(1), sum(mergeVSseg), 0.5);
% 
% pVal_thres = 0.05;
% if oneCellpValue < pVal_thres % probability of one cell in this region is low
%     one_cell_flag = 0;
% elseif 1-oneCellpValue < pVal_thres % probability of multi-cell in this region is low
%     one_cell_flag = 1;
% else
%     % no promising conclusion can be made, we use cumulative evidence
%     mergeVSseg = [1 0]; % 1-vs-more
%     for i=1:min(numel(left_tree)-1, numel(right_tree)-1)
%         if left_tree{numel(left_tree)-i}>1
%             mergeVSseg(2) = mergeVSseg(2) + 1;
%         else
%             mergeVSseg(1) = mergeVSseg(1) + 1;
%         end
%         
%         if right_tree{i+1}>1
%             mergeVSseg(2) = mergeVSseg(2) + 1;
%         else
%             mergeVSseg(1) = mergeVSseg(1) + 1;
%         end
%         oneCellpValue = binocdf(mergeVSseg(1), sum(mergeVSseg), 0.5);
%         if oneCellpValue < pVal_thres || (1-oneCellpValue) < pVal_thres
%             break;
%         end
%     end
%     if oneCellpValue < pVal_thres % probability of one cell in this region is low
%         one_cell_flag = 0;
%     elseif 1-oneCellpValue < pVal_thres % probability of multi-cell in this region is low
%         one_cell_flag = 1;
%     else
%         one_cell_flag = nan;
%     end
%     
% end
end