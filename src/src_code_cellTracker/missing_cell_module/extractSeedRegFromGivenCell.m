function [seed_region, missed_frames] = extractSeedRegFromGivenCell(...
    parent_kid_vec, refine_res, movieInfo, thresholdMaps, embryo_vid, eigMaps, q)
% given two footprints of the same cell (or one), get the seed in the 
% jumped frame in between
% NOTE: here we do not consider if the seed is already occupied by an
% existing cell, we will check this in the following steps
p_id = parent_kid_vec(1);
k_id = parent_kid_vec(2);
if isnan(p_id) || isnan(k_id)% starting point
    if ~isnan(k_id)
        missed_frames = movieInfo.frames(k_id)-1;
        idx = movieInfo.voxIdx{k_id};
        % transfer idx with given non-rigid drift info
        sz = size(embryo_vid{movieInfo.frames(k_id)});
        [idx_y, idx_x, idx_z] = ind2sub_direct(sz, idx);
        frame_shift = getNonRigidDrift([0 0 0], [mean(idx_x) mean(idx_y) mean(idx_z)], ...
            missed_frames, movieInfo.frames(k_id), movieInfo.drift, movieInfo.driftInfo);

    elseif ~isnan(p_id)
        missed_frames = movieInfo.frames(p_id)+1;
        idx = movieInfo.voxIdx{p_id};
        % transfer idx with given non-rigid drift info
        sz = size(embryo_vid{movieInfo.frames(p_id)});
        [idx_y, idx_x, idx_z] = ind2sub_direct(sz, idx);
        frame_shift = getNonRigidDrift([0 0 0], [mean(idx_x) mean(idx_y) mean(idx_z)], ...
            movieInfo.frames(p_id), missed_frames, movieInfo.drift, movieInfo.driftInfo);
    else
        error('At least one element in parent_kid_vec should be valid!');
    end

    idx_x = round(idx_x + frame_shift(1));
    idx_y = round(idx_y + frame_shift(2));
    idx_z = round(idx_z + frame_shift(3));
    % remove pixels out of the view
    invalid_flag = (idx_x < 1) | (idx_x > sz(2)) | (idx_y < 1) | ...
                       (idx_y > sz(1)) | (idx_z < 1) | (idx_z > sz(3));
    idx_x(invalid_flag) = []; 
    idx_y(invalid_flag) = [];
    idx_z(invalid_flag) = [];
    idx = sub2ind_direct(size(embryo_vid{missed_frames}), idx_y, idx_x, idx_z);
    
    if isempty(idx)
        seed_region = [];
        return;
    end
    seed_region = idx;
else
    missed_frames = movieInfo.frames(p_id)+1 : movieInfo.frames(k_id)-1;
    % find seed region: can be more complicated
    seed_region = intersect(movieInfo.voxIdx{p_id}, movieInfo.voxIdx{k_id});
end

%% pick the largest region indicated by the seed region
if isempty(seed_region)
    return;
end
[bw, st_pt, idx] = mapIdx2Bw(seed_region, size(thresholdMaps{1}));
[bw, rm_flag, idx] = pickLargestReg(bw, 6, idx);
if rm_flag   % otherwise, no need to change seed_region
    [yy, xx, zz] = ind2sub_direct(size(bw), idx);
    seed_region = sub2ind_direct(size(thresholdMaps{1}), yy+(st_pt(1)-1), ...
        xx+(st_pt(2)-1), zz+(st_pt(3)-1));
end


end