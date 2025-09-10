function flag = handleInconsistentParentKid(test_cell, movieInfo, refine_res, ...
    vidMap, eigMaps, q, g)
% two cases to handle the in consistent parent and kid nodes
% assumption: at least one the cell does not shift
% assumption: either parents or kids are correctly segmented
merge_both_parents_kids = 1;
split_by_parents = 3;
split_by_kids = 4;

cur_idx = movieInfo.voxIdx{test_cell};
cur_frame = movieInfo.frames(test_cell);
gapMaps = [];
% test two parents
sep_frame_p = movieInfo.frames(movieInfo.parents{test_cell}(1));
sep_idx_p = movieInfo.voxIdx(movieInfo.parents{test_cell});

[v_p, rv1, mp1, mp2] = bisectValidTest(cur_idx, ...
    cur_frame, sep_idx_p, sep_frame_p, movieInfo, vidMap, refine_res, eigMaps, ...
    gapMaps, g, q);
if ~v_p
    % second try: use intersection as seed regions to separate
    gapBased = false;
    [v_p, ~, mp1, mp2] = bisectValidTest(...
        cur_idx, cur_frame, sep_idx_p, sep_frame_p, movieInfo, ...
        vidMap, refine_res, eigMaps, gapMaps, g, q, gapBased);
end

% test two parents
sep_frame_k = movieInfo.frames(movieInfo.kids{test_cell}(1));
sep_idx_k = movieInfo.voxIdx(movieInfo.kids{test_cell});

[v_k, rv2, mk1, mk2] = bisectValidTest(cur_idx, ...
    cur_frame, sep_idx_k, sep_frame_k, movieInfo, vidMap, refine_res, eigMaps, ...
    gapMaps, g, q);
if ~v_k
    % second try: use intersection as seed regions to separate
    gapBased = false;
    [v_k, ~, mk1, mk2] = bisectValidTest(...
        cur_idx, cur_frame, sep_idx_k, sep_frame_k, movieInfo, ...
        vidMap, refine_res, eigMaps, gapMaps, g, q, gapBased);
end
flag = nan;
if v_p && v_k % there is segmentation error, not shifting
%     flag = merge_both_parents_kids;
    if max(mp1, mp2) > max(mk1, mk2)
        flag = split_by_kids;
    else
        flag = split_by_parents;
    end
elseif v_p % more possibly there is shifting/segmentaion error in kids
    flag = split_by_parents;
elseif v_k % more possibly there is shifting/segmentaion error in parents
    flag = split_by_kids;
% else % indeed this is not needed, because when we link allowing not split
% or merge, the 'test_cell' will automatically assigned to one of the track
%     valid_p = find([mp1, mp2]<abs(g.observationCost));
%     if ~isempty(valid_p)
%         frames = [cur_frame, sep_frame_k];
%         [mc, ~] = voxIdx2cost(rv1{valid_p}, sep_idx_k{1}, frames, ...
%             movieInfo, refine_res);
%         if mc >= abs(g.observationCost)
%             [mc, ~] = voxIdx2cost(rv1{valid_p}, sep_idx_k{2}, frames, ...
%                 movieInfo, refine_res);
%         end
%         if mc < abs(g.observationCost)
%             flag = split_by_parents;
%             return;
%         end
%     end
%     valid_k = find([mk1, mk2]<abs(g.observationCost));
%     if ~isempty(valid_k)
%         frames = [cur_frame, sep_frame_p];
%         [mc, ~] = voxIdx2cost(rv2{valid_k}, sep_idx_p{1}, frames, ...
%             movieInfo, refine_res);
%         if mc >= abs(g.observationCost)
%             [mc, ~] = voxIdx2cost(rv2{valid_k}, sep_idx_p{2}, frames, ...
%                 movieInfo, refine_res);
%         end
%         if mc < abs(g.observationCost)
%             flag = split_by_kids;
%             return;
%         end
%     end
end
end