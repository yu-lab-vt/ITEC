function [bestNei, bestCij] = bestCijNei(node_id, movieInfo, frame, preFlag)
% find the neighbor with smallest linking cost in a given frame
if nargin == 3
    preFlag = false;
end
if preFlag
    nei = movieInfo.preNei{node_id};
    ovCij = movieInfo.Cji{node_id};
else
    nei = movieInfo.nei{node_id};
    ovCij = movieInfo.Cij{node_id};
end

frames = movieInfo.frames(nei);
cur_locs = find(frames==frame);
if isempty(cur_locs)
    bestNei = nan;
    bestCij = 0;
else
    nei = nei(cur_locs);
    ovCij = ovCij(cur_locs);
    [bestCij, od] = min(ovCij);
    bestNei = nei(od);
end
end