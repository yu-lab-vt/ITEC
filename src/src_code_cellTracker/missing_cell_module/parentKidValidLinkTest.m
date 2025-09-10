function [flag, maxCost1, maxCost2] = parentKidValidLinkTest(append_idx, ...
    append_frame, parent_kid_vec, movieInfo, refine_res, g)
% given an cell, test if it could link to the given parent cell or kid cell

maxCost1 = inf;
maxCost2 = inf;
if isnan(parent_kid_vec(1)) && isnan(parent_kid_vec(2))
    %warning('At least one region is valid!');
    flag = 0;
    return;
end
if ~isnan(parent_kid_vec(1))
    frames = [movieInfo.frames(parent_kid_vec(1)), append_frame];
    [maxCost1, ~] = voxIdx2cost(movieInfo.voxIdx{parent_kid_vec(1)}, ...
        append_idx, frames, movieInfo, size(refine_res{1}));
end
if ~isnan(parent_kid_vec(2)) 
    frames = [append_frame, movieInfo.frames(parent_kid_vec(2))];
    [maxCost2, ~] = voxIdx2cost(append_idx, ...
        movieInfo.voxIdx{parent_kid_vec(2)}, frames, movieInfo, ...
        size(refine_res{1}));
end
if (isinf(maxCost1) || isinf(maxCost2)) && min([maxCost1, maxCost2]) < abs(g.observationCost)
    flag = true;
elseif max([maxCost1, maxCost2]) < abs(g.observationCost)
    flag = true;
else
    flag = false;
end

end