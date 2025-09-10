function [flag, regVoxIdx, maxCost1, maxCost2] = bisectValidTest(cur_idx, ...
    cur_frame, sep_idx, sep_frame, movieInfo, vidMap, refine_res, eigMaps, ...
    gapMaps, g, q, gapBased)
% separate a region to two regions and test if the resultant two regions
% are meaningful based on the two seeds for separation
if nargin == 11
    gapBased = true;
end

if gapBased % using gap to separate the current region (eigMaps)
    regVoxIdx = bisectRegion_gapguided(cur_idx, cur_frame, sep_idx, ...
        vidMap, refine_res, eigMaps, gapMaps, q);
else% otherwise use seed regions (sep_idx)
    regVoxIdx = bisectRegion(cur_idx, cur_frame, sep_idx, sep_frame,...
        vidMap, refine_res, eigMaps, gapMaps, q);
end
frames = [cur_frame, sep_frame];
[maxCost1, ~] = voxIdx2cost(regVoxIdx{1}, sep_idx{1}, frames, ...
    movieInfo, refine_res);
[maxCost2, ~] = voxIdx2cost(regVoxIdx{2}, sep_idx{2}, frames, ...
    movieInfo, refine_res);

if max(maxCost1, maxCost2) >= abs(g.observationCost)
    flag = false;
else
    flag = true;
end

end