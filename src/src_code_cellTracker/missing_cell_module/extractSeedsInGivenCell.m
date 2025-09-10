function [yxz, new_p_k_vec] = extractSeedsInGivenCell(cell_id, ...
    cell_1stSeed, cell_1stSeed_idx, movieInfo, refine_res, ...
    embryo_vid, thresholdMaps, eigMaps, parent_flag, q)
% extract all the seeds that contained in current cell
% seedBase indicate which frame should we consider
frame4detect_cell_family = movieInfo.frames(cell_1stSeed);

if parent_flag
    cell_family_f = movieInfo.frames(movieInfo.parents{cell_id});
else
    cell_family_f = movieInfo.frames(movieInfo.kids{cell_id});
end
new_p_k_vec = [];
%% get all possible parents or kids
possible_cells = [];
test_frame = movieInfo.frames(cell_id);
if frame4detect_cell_family ~= cell_family_f % if the candidate has a parent in
    % this frame, then we should skip
    [possible_cells, neis_PorK_frame] = ...
        extractParentsOrKidsGivenCell(...
        movieInfo, cell_id, test_frame, frame4detect_cell_family, parent_flag);
end
yxz = [];
if length(possible_cells) > 2 % if only 2 cell, then no need to process here
    % if more than 2 cell, split/merge test cannot handle
    yxz = cell(length(possible_cells), 1);
    yxz{1} = cell_1stSeed_idx;
    cnt = 1;
    cell_real_label = refine_res{test_frame}(movieInfo.voxIdx{cell_id}(1));
    new_p_k_vec = nan(length(possible_cells), 2);
    for i=1:length(possible_cells)
        if parent_flag
            if ~isnan(neis_PorK_frame(i))
                parent_kid_vec = [possible_cells(i) ...
                    movieInfo.kids{possible_cells(i)}];
            else
                parent_kid_vec = [possible_cells(i) nan];
            end
        else
            if ~isnan(neis_PorK_frame(i))
                parent_kid_vec = [movieInfo.parents{possible_cells(i)} ...
                    possible_cells(i)];
            else
                parent_kid_vec = [nan possible_cells(i)];
            end
        end
        if possible_cells(i)==cell_1stSeed
            new_p_k_vec(1,:) = parent_kid_vec;
            continue;
        end
        seed_region = extractSeedRegFromGivenCell(...
            parent_kid_vec, refine_res, movieInfo, thresholdMaps, embryo_vid, eigMaps, q);
        
        ids = refine_res{test_frame}(seed_region);
        % we only consider seeds fully inside the candidate large region
        tmp_yxz = seed_region(ids==0 | ismember(ids, cell_real_label));
        if length(tmp_yxz) > max(q.minSeedSize, 0.5*length(seed_region))
            % start from 2, 1st position was left for cell_1st
            cnt = cnt + 1;
            new_p_k_vec(cnt,:) = parent_kid_vec;
            yxz{cnt} = tmp_yxz;
        end
    end
    new_p_k_vec = new_p_k_vec(1:cnt,:);
    if cnt > 2
        yxz = yxz(1:cnt);
    else
        yxz = [];
    end
end
%if ~isempty(find(sum(isnan(new_p_k_vec),2)==2, 1))
%    warning('invalid parent kid vector!');
%end
end