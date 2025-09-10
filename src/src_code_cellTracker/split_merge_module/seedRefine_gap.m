function seedMap = seedRefine_gap(eigMap, seedMap, connect, eigThreshold)
% given a seed map, remove voxels that with large principal curvature
% values
if nargin == 3
    eigThreshold = 0;
end
if nargin == 2
    connect = 26;
    eigThreshold = 0;
end
if isa(eigMap, 'logical')
    possibleGapMap = eigMap;
else
    possibleGapMap = eigMap>eigThreshold;
end
orgSeedMap = seedMap;
seedMap(possibleGapMap) = 0;

seedMap = pickLargestReg(seedMap, connect);
if isempty(seedMap)
    seedMap = orgSeedMap;
end
% [l,n] = bwlabeln(seedMap, 26);
% if n==1
%     seedMap = l>0;
% elseif n==0
%     seedMap = orgSeedMap;
% else
%     s = regionprops3(l,'Volume');
%     [~,od] = max([s.Volume]);
%     seedMap = ismember(l, od);
% end

end