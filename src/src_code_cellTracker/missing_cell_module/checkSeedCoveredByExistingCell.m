function [yxz, new_p_k_vec, invalid_locs] = checkSeedCoveredByExistingCell(seed_region, ...
    p_k_vec, movieInfo, refine_res, embryo_vid, thresholdMaps, eigMaps, missed_frame, q)
% when retrieve missing cell, the seed we get may already be covered by an
% existing cell. It is worthy to check if the cell is real or an
% over-merged one, because it cannot be linked to the cell represented by
% the seed.
min_seed_sz = max(q.minSeedSize, 0.5*length(seed_region));
ids = refine_res{missed_frame}(seed_region);
%% way 1: if the cell is an orphan. Remove it and re-check
ovId_Cnt = frequency_cnt(ids(ids>0));
can_ids = ovId_Cnt(:,1);%unique(ids(ids>0));
old_ids = can_ids <= movieInfo.n_perframe(missed_frame);
can_locs = can_ids;
can_locs(old_ids) = can_locs(old_ids) + ...
    sum(movieInfo.n_perframe(1:missed_frame-1));
% way1: if the node has no parent and kid
p_len = cellfun(@length, movieInfo.parents(can_locs));
k_len = cellfun(@length, movieInfo.kids(can_locs));
invalid_ids = can_ids(p_len + k_len == 0);

invalid_locs = [];
yxz = [];
new_p_k_vec = p_k_vec;
if ~isempty(invalid_ids)
    % remove orhpans and we will have valid seed region
    invalid_locs = can_locs(p_len + k_len == 0);
    % update yxz
    yxz = seed_region(ids<=0 | ismember(ids, invalid_ids));
end

if length(yxz) >= min_seed_sz
    return;
end

%% way 2: if way 1 failed, it is possible the region is an over-merged one
% find the most possibly over-merged region
[~,od] = max(ovId_Cnt(:,2));
cell_1stSeed_idx = seed_region(ids<=0 | ismember(ids, can_ids(od)));
if length(cell_1stSeed_idx) <= min_seed_sz
    yxz = [];
    invalid_locs = [];
    return;
end
candidate_reg = can_locs(od);

yxz = [];
if ~isnan(p_k_vec(1))
    parent_flag = true;
    [yxz, new_p_k_vec] = extractSeedsInGivenCell(candidate_reg, ...
        p_k_vec(1), cell_1stSeed_idx, movieInfo, refine_res, ...
        embryo_vid, thresholdMaps, eigMaps, parent_flag, q);
end

if numel(yxz) < 3 && ~isnan(p_k_vec(2))
    parent_flag = false;
    [yxz, new_p_k_vec] = extractSeedsInGivenCell(candidate_reg, ...
        p_k_vec(2), cell_1stSeed_idx, movieInfo, refine_res, ...
        embryo_vid, thresholdMaps, eigMaps, parent_flag, q);
end

if numel(yxz) < 3 % 2 cell can be handled by merge/split
    yxz = [];
    invalid_locs = [];
    new_p_k_vec = p_k_vec;
else
    invalid_locs = candidate_reg;
    if ~q.multiSeedProcess
        yxz = yxz{1};
        new_p_k_vec = p_k_vec;
    end
end


