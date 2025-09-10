function [ovSize, CDist, Cij, ov_dist_dirWise] = nodes_relations(movieInfo, curNode, neiNode, g)

%% This function is to calculate overlapping size distance and cost between two nodes

ovSize = length(intersect(movieInfo.voxIdx{curNode},...
    movieInfo.voxIdx{neiNode}));
if ovSize == 0
    ov_dist = 1000;
    ov_dist_dirWise = [1000 1000];
    edgeCost = inf;
else
    if g.applyDrift2allCoordinate
        [ov_dist, ~, ov_dist_dirWise] = ovDistanceRegion(movieInfo.vox{curNode},...
            movieInfo.vox{neiNode});
    else
        frame_shift = getNonRigidDrift(movieInfo.vox{curNode}, movieInfo.vox{neiNode},...
            movieInfo.frames(curNode), movieInfo.frames(neiNode), movieInfo.drift, g.driftInfo);
        [ov_dist, ~, ov_dist_dirWise] = ovDistanceRegion(movieInfo.vox{curNode},...
            movieInfo.vox{neiNode}, frame_shift);
    end
    fr_diff = movieInfo.frames(neiNode) - movieInfo.frames(curNode);
    if isfield(movieInfo, 'jumpRatio')
        edgeCost = overlap2cost(ov_dist, movieInfo.ovGamma, movieInfo.jumpRatio(fr_diff));
    else
        edgeCost = overlap2cost(ov_dist, movieInfo.ovGamma);
    end
    edgeCost = min(1000, edgeCost);
end
CDist = ov_dist;
Cij = edgeCost;
if isnan(edgeCost)
    fprintf('We found NaN edge cost!!!\n');
end

end