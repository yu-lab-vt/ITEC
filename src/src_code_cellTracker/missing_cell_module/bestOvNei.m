function [bestNei, bestOvSz] = bestOvNei(node_id, movieInfo, frame, preFlag)
% find the neighbor with largest overlapping size in a given frame
if nargin == 3
    cur_f = movieInfo.frames(node_id);
    if cur_f > frame
        preFlag = true;
    else
        preFlag = false;
    end
end
if preFlag
    nei = movieInfo.preNei{node_id};
    ovSz = movieInfo.preOvSize{node_id};
else
    nei = movieInfo.nei{node_id};
    ovSz = movieInfo.ovSize{node_id};
end

frames = movieInfo.frames(nei);
cur_locs = find(frames==frame);
if isempty(cur_locs)
    bestNei = nan;
    bestOvSz = 0;
else
    nei = nei(cur_locs);
    ovSz = ovSz(cur_locs);
    [bestOvSz, od] = max(ovSz);
    bestNei = nei(od);
end
end