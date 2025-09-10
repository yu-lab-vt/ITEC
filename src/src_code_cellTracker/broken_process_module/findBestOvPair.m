function bestNei = findBestOvPair(movieInfo, cur_i, q)

%% This function is to find the nearest neighbor in the next frame with given conditions
% INPUT:
%     cur_i: current cell id
% OUTPUT:
%     bestNei: nearest neighbor in the next frame
%          [] means no satisfied neighbor found  

% set parameters
if nargin == 2
    im_resolution = [1 1 1];
    max_dist = 50;
    max_nei = 5;
elseif nargin == 3
    im_resolution = q.im_resolution;
    max_dist = q.max_dist;
    max_nei = q.max_nei;
end

bestNei = [];
tt = movieInfo.frames(cur_i);
curCentroid = movieInfo.orgCoord(cur_i,:);
nextCentroid = movieInfo.orgCoord(movieInfo.frames==(tt+1),:);

% candidate neighbors roughly selection
drift = getNonRigidDrift([0 0 0], movieInfo.orgCoord(cur_i,:), tt, tt+1, movieInfo.drift, movieInfo.driftInfo);
dist_pair = pdist2((curCentroid + drift).*im_resolution, nextCentroid.*im_resolution); % not accurate but enough
[neighbor_dist, neighbor_candidate] = sort(dist_pair);
neighbor_dist = neighbor_dist(1,1:min(max_nei, length(dist_pair)));
neighbor_candidate = neighbor_candidate(1,1:min(max_nei, length(dist_pair)));
neighbors = neighbor_candidate(neighbor_dist < max_dist);

% find the nearest neighbor
if ~isempty(neighbors)
    neighbors = neighbors + sum(movieInfo.n_perframe(1:tt)); % change to orignal 
    distances = nan(length(neighbors), 1);
    for ii = 1:length(neighbors)
        drift = getNonRigidDrift(movieInfo.orgCoord(cur_i,:), ...
            movieInfo.orgCoord(neighbors(ii),:), tt, tt+1, movieInfo.drift, movieInfo.driftInfo);
        [distances(ii), ~, ~, ~] = ...
            ovDistanceRegion(movieInfo.vox{cur_i}, movieInfo.vox{neighbors(ii)}, drift);  
    end
    [~, bestNei] = min(distances);
    bestNei = neighbors(bestNei);
end
