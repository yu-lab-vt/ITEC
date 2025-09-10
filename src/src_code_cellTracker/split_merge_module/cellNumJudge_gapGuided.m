function [one_cell_flag, p_value, mergeVSseg] = ...
    cellNumJudge_gapGuided(left_cells, right_cells, movieInfo, ...
    refine_res, vidMap, g, eigMaps, q, o2m_flag)
% left_cells: left tree with leaf ids in the same level in the same cell
% right_cells: right tree with leaf ids in the same level in the same cell

% July. 6th, 2020
one_cell_flag = nan;
left_cnt = cellfun(@length, left_cells); % both are start from root node
right_cnt = cellfun(@length, right_cells);
pVal_thres = 0.05;
p_value = 0.5;
%% way 1: the neighbors of the root node lead to consistent conclusion
% no promising conclusion can be made, we use cumulative evidence
% pVal_thres = 0.01;
mergeVSseg = [1 0]; % 1-vs-more
oneCellpValue = 0.5; % initialize as non-significant
multiCellpValue = 0.5; % initialize as non-significant
for i=1:min([numel(left_cnt)-1, numel(right_cnt)-1, 10])
    if i+1 <= length(left_cnt)
        if left_cnt(i+1)>1
            mergeVSseg(2) = mergeVSseg(2) + 1;
        else
            mergeVSseg(1) = mergeVSseg(1) + 1;
        end
    end
    if i+1 <= length(right_cnt)
        if right_cnt(i+1)>1
            mergeVSseg(2) = mergeVSseg(2) + 1;
        else
            mergeVSseg(1) = mergeVSseg(1) + 1;
        end
    end
    oneCellpValue = binocdf(mergeVSseg(1), sum(mergeVSseg), 0.5);
    multiCellpValue = binocdf(mergeVSseg(2), sum(mergeVSseg), 0.5);
    if min(multiCellpValue, oneCellpValue) < pVal_thres
        break;
    end
end
if oneCellpValue < pVal_thres % probability of one cell in this region is low
    p_value = oneCellpValue;
    one_cell_flag = 0;
    return;
end
if multiCellpValue < pVal_thres % probability of multi-cell in this region is low
    p_value = multiCellpValue;
    one_cell_flag = 1;
    return;
end

%% way 2.2: if the regions in the same frame are not spatially adjacent or 
% there is stable nodes, split them
left_adjacent_flag = true(numel(left_cells), 1); %
left_separate_flag = nan;
for i=2:numel(left_cells)
    if left_cnt(i)>1
        if sum(~isinf(movieInfo.arc_avg_mid_std(left_cells{i},4)))>0 && g.stableNodeTest
            left_adjacent_flag(i) = false;
        else
            for j=1:left_cnt(i)-1
                [~, adj_ids] = regionAdjacent(movieInfo, refine_res, ...
                    left_cells{i}(j));
                %if isempty(intersect(adj_ids, left_cells{i}))%
                if length(intersect(adj_ids, left_cells{i})) ~= left_cnt(i)-1
                    left_adjacent_flag(i) = false;
                    break;
                end
            end
        end
    else
        left_separate_flag = false;
    end
    if ~left_adjacent_flag(i)
        if isnan(left_separate_flag)
            left_separate_flag = true;
        end
        break;
    end
end
% case 1: the regions are spatially separate on the left side
if left_separate_flag == true
    one_cell_flag = 0;
    return;
end
right_adjacent_flag = true(numel(right_cells),1);
right_separate_flag = nan;
for i=2:numel(right_cells)
    if right_cnt(i)>1
        if sum(~isinf(movieInfo.arc_avg_mid_std(right_cells{i},4)))>0 && g.stableNodeTest
            right_adjacent_flag(i) = false;
        else
            for j=1:right_cnt(i)-1
                [~, adj_ids] = regionAdjacent(movieInfo, refine_res, ...
                    right_cells{i}(j));
                %if isempty(intersect(adj_ids, right_cells{i}))%
                if length(intersect(adj_ids, right_cells{i})) ~= right_cnt(i)-1
                    right_adjacent_flag(i) = false;
                    break;
                end
            end
        end
    else
        right_separate_flag = false;
    end
    if ~right_adjacent_flag(i)
        if isnan(right_separate_flag)
            right_separate_flag = true;
        end
        break;
    end
end
% case 1: the regions are spatially separate on the right side
if right_separate_flag == true
    one_cell_flag = 0;
    return;
end

%% way 3: the neighbors of the root node lead to consistent conclusion
% no promising conclusion can be made, we use cumulative evidence
if true
    max_num_frame_include = 10;
    sz_diff_adj_frames = nan(length(left_cnt) + length(right_cnt) - 2, 1);
    sz_diff2test_region_left = zeros(length(left_cnt), 1);
    for i=1:length(left_cnt)-1
        sz_diff_adj_frames(i) = ...
            sum(cellfun(@length, movieInfo.voxIdx(left_cells{i}))) - ...
            sum(cellfun(@length, movieInfo.voxIdx(left_cells{i+1})));
        
        sz_diff2test_region_left(i+1) = ...
            sum(cellfun(@length, movieInfo.voxIdx(left_cells{i+1}))) - ...
            sum(cellfun(@length, movieInfo.voxIdx(left_cells{1})));
    end
    sz_diff2test_region_right = zeros(length(right_cnt), 1);
    for i=1:length(right_cnt)-1
        sz_diff_adj_frames(length(left_cnt)-1 + i) = ...
            sum(cellfun(@length, movieInfo.voxIdx(right_cells{i+1}))) - ...
            sum(cellfun(@length, movieInfo.voxIdx(right_cells{i})));
        sz_diff2test_region_right(i+1) = ...
            sum(cellfun(@length, movieInfo.voxIdx(right_cells{i+1}))) - ...
            sum(cellfun(@length, movieInfo.voxIdx(right_cells{1})));
    end
    sz_std = nanstd(sz_diff_adj_frames);
    mergeVSseg = [1 0]; % 1-vs-more
    oneCellpValue = 0.5; % initialize as non-significant
    multiCellpValue = 0.5; % initialize as non-significant
    for i=1:min(max(numel(left_cnt)-1, numel(right_cnt)-1), max_num_frame_include)
        if i+1 <= length(left_cnt)
            if abs(sz_diff2test_region_left(i+1)) < sz_std
                if left_cnt(i+1)>1
                    mergeVSseg(2) = mergeVSseg(2) + 1;
                else
                    mergeVSseg(1) = mergeVSseg(1) + 1;
                end
            end
        end
        if i+1 <= length(right_cnt)
            if abs(sz_diff2test_region_right(i+1)) < sz_std
                if right_cnt(i+1)>1
                    mergeVSseg(2) = mergeVSseg(2) + 1;
                else
                    mergeVSseg(1) = mergeVSseg(1) + 1;
                end
            end
        end
        oneCellpValue = binocdf(mergeVSseg(1), sum(mergeVSseg), 0.5);
        multiCellpValue = binocdf(mergeVSseg(2), sum(mergeVSseg), 0.5);
        if min(multiCellpValue, oneCellpValue) < pVal_thres
            break;
        end
    end
    if oneCellpValue < pVal_thres % probability of one cell in this region is low
        %p_value = oneCellpValue;
        one_cell_flag = 0;
        return;
    end
    if multiCellpValue < pVal_thres % probability of multi-cell in this region is low
        %p_value = multiCellpValue;
        one_cell_flag = 1;
        return;
    end
end
%% way 4.1 test if the region is a small piece of shit
% two split regions that consistent with its two kid or parent regions
root_node = right_cells{1};
% we firstly use kids, because we test one2multiple first
if o2m_flag
    bases = movieInfo.kids{root_node};
    base_nei = movieInfo.kids(bases);
else
    bases = movieInfo.parents{root_node};
    base_nei = movieInfo.parents(bases);
end
if length(bases) == 2
    validFlag = mergeValidTest(root_node, bases, movieInfo, refine_res, g);
    if validFlag
        one_cell_flag = 1;
        return;
    end
end
%% way 4.2: test if the principal curvature can split current region into
if length(bases) == 2 % only consider one region linking to two regions
    % do further test
    root_voxIdx = movieInfo.voxIdx{root_node};
    root_frame = movieInfo.frames(root_node);
    base_voxIdx = movieInfo.voxIdx(bases);

    validFlag = bisectValidTest(root_voxIdx, root_frame, base_voxIdx, ...
        movieInfo.frames(bases(1)), movieInfo, vidMap, refine_res, ...
        eigMaps, movieInfo.validGapMaps, g, q);
    if sum(find(left_cnt>1)<=6) == 5 || sum(find(right_cnt>1)<=6) == 5
        % based on binomial distribution, P(5 consecutive splitting)<0.05
        single_side_split_flag = true;
    else
        single_side_split_flag = false;
    end
    % the two kids/parents must be adjacent, otherwise we should already
    % have decision
    %if max(maxCost1, maxCost2) < inf 
        % should we make a decision for no
        %gaps? no gaps means max(maxCost1, maxCost2) == inf
    if validFlag || max(length(base_nei{1}), length(base_nei{2}))>1 ...
            || single_side_split_flag
        % (1) gap exists for spliting.
        % (2) more than two ancestors or kids exist.
        % (3) one side show solid evidence of spliting. then we will
        % force the region to split. if it can, then split. Otherwise,
        % it is quite possible there is an noise region, we will
        % nullify the relationship of it.
        one_cell_flag = 0;
    elseif length(base_nei{1}) == length(base_nei{2})
        % if merge these two nodes will not generate orphans, we merge
        % them
        one_cell_flag = 1;
    end
  
end
