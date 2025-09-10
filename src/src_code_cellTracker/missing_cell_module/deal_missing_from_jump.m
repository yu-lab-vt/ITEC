function [movieInfo, refine_res, thresholdMaps, upt_ids] = ...
    deal_missing_from_jump(movieInfo, refine_res, embryo_vid,...
    thresholdMaps, parent_kid_vec, eigMaps, g, q)
% if there is jump/stop/start, check if there is missing cells in the
% overlooked frames; The basic idea is
% (1) find seed region
% (2) re-threshold the local area
% (3) test if the region is adjacent to other regions, if so, test if we 
% should merge the new region to it; otherwise add a new region

%% get seed region from adjacent frames
[seed_region, missed_frames] = extractSeedRegFromGivenCell(...
    parent_kid_vec, refine_res, movieInfo, thresholdMaps, embryo_vid, eigMaps, q);
if length(seed_region) < q.minSeedSize || length(seed_region) > q.maxSeedSize
    upt_ids = [];
    return;
end
parent_kid_vec_org = parent_kid_vec;
upt_ids = cell(length(missed_frames), 1);
for i=1:length(missed_frames)
    parent_kid_vec = parent_kid_vec_org;
    upt_ids{i} = [];
    ids = refine_res{missed_frames(i)}(seed_region);
    yxz = seed_region;
    yxz(ids>0) = [];
    invalid_locs = [];
    min_seed_sz = q.minSeedSize;
    if ~g.addCellMissingPart
        % we only detect fully missed cells, so seed that highly
        % overlapped with an existing cell will be removed
        min_seed_sz = max(q.minSeedSize, 0.5*length(seed_region));
        if length(yxz) < 0.5*length(seed_region)
            [yxz, parent_kid_vec, invalid_locs] = checkSeedCoveredByExistingCell...
                (seed_region, parent_kid_vec, movieInfo, refine_res, embryo_vid,...
                thresholdMaps, eigMaps, missed_frames(i), q);
            if ~isempty(invalid_locs)
                [movieInfo, refine_res, thresholdMaps, rm_cell_id_idx_p_k] ...
                    = nullify_region(invalid_locs, movieInfo, refine_res, ...
                    thresholdMaps, false);
            end
        end
    end
    if ~iscell(yxz)
        if length(yxz) < min_seed_sz
            yxz = [];
        end
    end
    %% re-detect the foreground
    [comMaps, pseudo_seed_label] = redetectCellinTrackingwithSeed(movieInfo,...
     refine_res, embryo_vid, thresholdMaps, parent_kid_vec, eigMaps, missed_frames(i), yxz, q);
    % if we don't find valid foreground region, try again
    if isempty(find(comMaps.fmapComp,1)) & all(~isnan(parent_kid_vec)) & ...
            length(yxz) >= 0.9*length(seed_region)
        [comMaps, pseudo_seed_label] = redetectCellinTrackingwithSeed(movieInfo,...
            refine_res, embryo_vid, thresholdMaps, parent_kid_vec, eigMaps, ...
            missed_frames(i), yxz, q, false);    
    end
    % test if the missing cell is valid
    upt_ids_new = [];
    if ~isempty(find(comMaps.fmapComp,1))
        if isscalar(pseudo_seed_label)
            if size(parent_kid_vec,1)>1
                warning('conflict choice!');
            end
            [movieInfo, refine_res, thresholdMaps, upt_ids_new] = ...
                testMissingCellGotFromOneSeed(comMaps, pseudo_seed_label, ...
                parent_kid_vec, missed_frames(i), movieInfo, refine_res, thresholdMaps,...
                embryo_vid, eigMaps, g, q);
        elseif length(pseudo_seed_label) > 1
            [movieInfo, refine_res, thresholdMaps, upt_ids_new] = ...
                testMissingCellGotFromMultiSeeds(comMaps, pseudo_seed_label, ...
                parent_kid_vec, missed_frames(i), movieInfo, refine_res, thresholdMaps,...
                embryo_vid, g);
        end
    end
    if ~isempty(upt_ids_new)
        upt_ids{i} = cat(1, upt_ids{i}, invalid_locs, upt_ids_new);
    elseif ~isempty(invalid_locs)   % no valid cell detected, we roll back
        movieInfo.voxIdx(invalid_locs) = rm_cell_id_idx_p_k{2};
        movieInfo.parents(invalid_locs) = rm_cell_id_idx_p_k{3};
        movieInfo.kids(invalid_locs) = rm_cell_id_idx_p_k{4};
        for j = 1:length(invalid_locs)
            f_cur = movieInfo.frames(invalid_locs(j));
            refine_res{f_cur}(movieInfo.voxIdx{invalid_locs(j)}) = ...
                rm_cell_id_idx_p_k{1}(j,2);
            thresholdMaps{f_cur}(movieInfo.voxIdx{invalid_locs(j)}) = ...
                rm_cell_id_idx_p_k{1}(j,3);
        end
    end
       
end
upt_ids = cat(1, upt_ids{:});
if isempty(upt_ids)       % make them consistent (e.g. 0*1 and 1*0)
    upt_ids = [];
end