function [movieInfo,refine_res, thresholdMaps, upt_ids] = ...
    testMissingCellGotFromOneSeed(comMaps, pseudo_seed_label, ...
    parent_kid_vec, missed_frame, movieInfo,refine_res, thresholdMaps,...
    embryo_vid,eigMaps, g, q)
% if we detected a cell with a given seed, we need to test its relationship
% with its surrounding cells. Should we merge them?

upt_ids = [];
idsAndLocs = [];

% if the new region adjacent to an existing cell
% should we consider z-direction???
cur_nei_regions = comMaps.idComp(...
    imdilate(comMaps.regComp, strel('disk', 1)) & ~comMaps.regComp);

cur_regions_cnt = frequency_cnt(cur_nei_regions(cur_nei_regions>0 ...
    & cur_nei_regions~=pseudo_seed_label));
if ~isempty(find(cur_regions_cnt(:,1)~=0,1)) % there indeed an adjacent cell, merge them
    [~, od] = max(cur_regions_cnt(:,2));
    adj_cell = cur_regions_cnt(od,1);
    if adj_cell <= movieInfo.n_perframe(missed_frame)
        adj_cell_id = sum(movieInfo.n_perframe(1:missed_frame-1)) ...
            + adj_cell;
    else
        adj_cell_id = adj_cell;% this is a new region whose label is
        % just its id in movieInfo
    end
    if isempty(movieInfo.voxIdx{adj_cell_id})
        adj_cell_id = [];
        
    elseif refine_res{missed_frame}(movieInfo.voxIdx{adj_cell_id}(1))...
            ~= adj_cell
        error('The adjacent cell is wrong!');
    end
else % there no adjacent cell, then create a new cell
    adj_cell_id = [];
end
append_idx = comMaps.linerInd(comMaps.fmapComp);

if g.blindmergeNewCell%!!! if we blindly merge
    if isempty(adj_cell_id)
        flag = [1 1];
    else
        flag = [2 1];
    end
else
    [flag, newSplitIdx] = newlyAddedCellValidTest(append_idx, missed_frame, ...
        adj_cell_id, parent_kid_vec, movieInfo, refine_res, embryo_vid,...
        eigMaps, comMaps, g, q);
end

if flag(2) ~= 0 && ...
        (~q.removeSamllRegion || length(append_idx) >= q.minSize)
    % flag(1) = [2 3 5] ==> merge, for 3, we can split now
    % flag(1) = [1 4] ==> split
    if ismember(flag(1), [2 5])
        new_voxIdx = cat(1, movieInfo.voxIdx{adj_cell_id}, append_idx);
        movieInfo.voxIdx{adj_cell_id} = new_voxIdx;
        refine_res{missed_frame}(append_idx) = adj_cell;
        local_id = comMaps.fmapComp|(comMaps.idComp == adj_cell_id);
        thresholdMaps{missed_frame}(new_voxIdx) = round(quantile(...
                         comMaps.vidComp(local_id),0.5));
        upt_ids = cat(1, upt_ids, adj_cell_id);
    else
        if flag(1) == 3 % update current node/newly added node
            if isempty(newSplitIdx)
                error('newSplitIdx not assigned!');
            end
            append_idx = newSplitIdx{2};
            old_idx = movieInfo.voxIdx{adj_cell_id};
            refine_res{missed_frame}(old_idx) = 0;
            refine_res{missed_frame}(newSplitIdx{1}) = adj_cell;
            old_thres = thresholdMaps{missed_frame}(old_idx(1));
            if old_thres == 0
                warning('threshold not assigned!');
            end
            thresholdMaps{missed_frame}(old_idx) = 0;
            thresholdMaps{missed_frame}(newSplitIdx{1}) = old_thres;
            movieInfo.voxIdx{adj_cell_id} = newSplitIdx{1};
            upt_ids = cat(1, upt_ids, adj_cell_id);
        elseif flag(1) == 6 % update the index of the newly added node
            if isempty(newSplitIdx)
                error('newSplitIdx not assigned!');
            end
            append_idx = newSplitIdx;
        end
        % case 1 and 4, we can directly add the new cell
        movieInfo = addNewCell2MovieInfo(movieInfo, ...
            append_idx, parent_kid_vec, missed_frame);
        refine_res{missed_frame}(append_idx) = pseudo_seed_label;        
        upt_ids = cat(1, upt_ids, pseudo_seed_label);
        thresholdMaps{missed_frame}(append_idx) = round(quantile(...
                comMaps.vidComp(comMaps.fmapComp),0.5)); 
    end
       
    if ~isempty(idsAndLocs)
        upt_ids = cat(1, upt_ids, idsAndLocs(:,2));
    end
else % the new cell is invalid, continue to next, so roll back
    for j=1:size(idsAndLocs, 1)
        if ~isempty(voxIdxCells{j,2})
            movieInfo.voxIdx{idsAndLocs(j,2)} = voxIdxCells{j,1};
            refine_res{missed_frame}(voxIdxCells{j,2}) = 0;
            thresholdMaps{missed_frame}(voxIdxCells{j,2}) = 0;
        end
    end
end

end