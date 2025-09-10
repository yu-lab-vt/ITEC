function [neighbors,neighbor_dist] = findNeighbor(movieInfo, cur_i, paras, flag)

%% This function is to find k-nearest neighbors of certain cell
% INPUT:
%      movieInfo: tracking results
%      cur_i:id of certain cell
%      paras:parameters of tracking
%      flag:indicating frame direction
%      flag = 1:find the nearest neighbors in the next frame with given conditions  
%      flag = 0:find the nearest neighbors in the current frame with given conditions  
%      flag = -1:find the nearest neighbors in the last frame with given conditions 
% OUTPUT:
%      neighbors: id of neighbors of certain cell
%      neighbor_dist: distance of neighbors

im_resolution = paras.im_resolution;
max_nei = paras.max_nei + 1;
        
tt = movieInfo.frames(cur_i);
curCentroid = movieInfo.orgCoord(cur_i,:);
nextCentroid = movieInfo.orgCoord(movieInfo.frames==(tt+flag),:);
        
% candidate neighbors roughly selection
if tt >= min(movieInfo.frames) && tt+1 <=max(movieInfo.frames)
    drift = getNonRigidDrift([0 0 0], movieInfo.orgCoord(cur_i,:), tt, tt+1, movieInfo.drift, movieInfo.driftInfo);
else
    drift = 0;
end
dist_pair = pdist2((curCentroid + drift).*im_resolution, nextCentroid.*im_resolution); % not accurate but enough
[neighbor_dist, neighbor_candidate] = sort(dist_pair);
if flag == 0
    neighbor_dist = neighbor_dist(1,2:min(max_nei, length(dist_pair)));
    neighbor_candidate = neighbor_candidate(1,2:min(max_nei, length(dist_pair)));
else
    neighbor_dist = neighbor_dist(1,1:min(max_nei-1, length(dist_pair)));
    neighbor_candidate = neighbor_candidate(1,1:min(max_nei-1, length(dist_pair)));
end
neighbors = neighbor_candidate + sum(movieInfo.n_perframe(1:tt+flag-1));
end