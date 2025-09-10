function movieInfo = brown_var_estimation(movieInfo,paras)  

%% This function is to estimate the motion variance of cells
% INPUT:
%      movieInfo: tracking results
%      paras:parameters of tracking
% OUTPUT:
%      movieInfo: tracking results

t = length(movieInfo.n_perframe);
im_resolution = paras.im_resolution;
motion_var = zeros(t,3);
for ii = 2:t
    cell_ii = find(movieInfo.frames == ii);
    isEmptyCells = cellfun(@isempty, movieInfo.parents(cell_ii));
    cell_ii = cell_ii(~isEmptyCells);
    motion_pair = [cell2mat(movieInfo.parents(cell_ii)),cell_ii];
    motion_dist = zeros(length(cell_ii),3);
    for jj = 1:size(motion_pair,1)
        frame_shift = getNonRigidDrift([0 0 0], movieInfo.orgCoord(motion_pair(jj,2),:),...
         ii-1, ii, movieInfo.drift, movieInfo.driftInfo);
        motion_dist(jj,:) = (movieInfo.orgCoord(motion_pair(jj,1),:) + frame_shift - ...
                       movieInfo.orgCoord(motion_pair(jj,2),:)).*im_resolution;
    end
    motion_var(ii,:) = var(motion_dist,0,1);
end
movieInfo.motion_var = motion_var;
end