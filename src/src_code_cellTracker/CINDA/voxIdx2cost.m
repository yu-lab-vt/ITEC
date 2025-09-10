function [maxCost, minCost] = voxIdx2cost(voxIdx1, voxIdx2, frames, ...
    movieInfo, inputDataSize, jumpPunish)
% given two vox Idxes, calculate their cost
if nargin == 5
    jumpPunish = [];
end
if isempty(voxIdx1) || isempty(voxIdx2)
    maxCost = inf;
    minCost = inf;
    return;
end
if iscell(inputDataSize)
    [h,w,zslice] = size(inputDataSize{frames(1)});
else
    h = inputDataSize(1);
    w = inputDataSize(2);
    zslice = inputDataSize(3);
end
if size(voxIdx1, 2) == 1 %|| size(voxIdx1, 1) == 1
    [y, x, z] = ind2sub([h,w,zslice], voxIdx1);
    vox1 = [x, y, z];% - movieInfo.drift(frames(1),:);
else
    vox1 = voxIdx1;
end
if size(voxIdx2, 2) == 1 %|| size(voxIdx2, 1) == 1
    [y, x, z] = ind2sub([h,w,zslice], voxIdx2);
    vox2 = [x, y, z];% - movieInfo.drift(frames(2),:);
else
    vox2 = voxIdx2;
end
frame_shift = getNonRigidDrift(vox1, vox2, frames(1), frames(2), movieInfo.drift, movieInfo.driftInfo);
jump = abs(frames(2)-frames(1));
[maxDistance, minDistance] = ovDistanceRegion(vox1, vox2, frame_shift);
if jump < length(jumpPunish) && jump > 0
    maxCost = overlap2cost(maxDistance, movieInfo.ovGamma, ...
        jumpPunish(jump));
    minCost = overlap2cost(minDistance, movieInfo.ovGamma, ...
        jumpPunish(jump));
else
    maxCost = overlap2cost(maxDistance, movieInfo.ovGamma);
    minCost = overlap2cost(minDistance, movieInfo.ovGamma);
end
end