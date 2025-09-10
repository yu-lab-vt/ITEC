function [flag, maxCost, minCost] = voxIdxValidLinkTest(idx1, ...
    idx2, frames, movieInfo, refine_res, g)
% given an cell, test if it could link to the given parent cell or kid cell
[maxCost, minCost] = voxIdx2cost(idx1, ...
    idx2, frames, movieInfo, size(refine_res{1}));

if maxCost < abs(g.observationCost)
    flag = true;
else
    flag = false;
end

end