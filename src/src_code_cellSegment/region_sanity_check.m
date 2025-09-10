function [regLabel, redundant_flag] = region_sanity_check(regLabel, minSz, maxSz, ...
                               check_multi_seeds)

%% This function is to remove fp region with given size constraint
% and check if the region indeed contains multiple connected components. 
% INPUT:
%     regLabel: input label map
%     minSz: minimum size of seeds/cells
%     maxSz: maximum size of seeds/cells
%     check_multi_seeds: flag for handling multiple seeds
% OUTPUT:
%     regLabel: the output label map with each region containing only one
%     connected component for sures
%     redundant_flag: indicate whether there are excess seeds

if nargin == 1
    minSz = 1;
    maxSz = 10^6;
    check_multi_seeds = false;
elseif nargin == 2
    maxSz = 10^6;
    check_multi_seeds = false;
elseif nargin == 3
    check_multi_seeds = false;
end
if ~check_multi_seeds
    stats_org = regionprops3(regLabel,'Volume', 'VoxelIdxList');
    v = find([stats_org.Volume]<minSz | [stats_org.Volume]>maxSz);
    if isempty(v)
        redundant_flag = false;
    else
        redundant_flag = true;
        regLabel(ismember(regLabel, v)) = 0;
        regLabel = rearrange_id(regLabel);
    end
else 
    % not only check size, but also split regions with multiple connected comps
    n = double(max(regLabel(:)));
    stats_org = regionprops3(regLabel,'Volume', 'VoxelIdxList');
    new_l_map = bwlabeln(regLabel>0, 26);
    stats_new = regionprops3(new_l_map,'Volume', 'VoxelIdxList');
    redundant_flag = false;
    regCnt = 0;
    regLabelOut = zeros(size(regLabel));
    for i=1:n
        voxIdx = stats_org.VoxelIdxList{i};
        if length(voxIdx) <= minSz || length(voxIdx) >= maxSz
            continue;
        end
        ids = unique(new_l_map(voxIdx));
        n0 = length(ids);
        if n0>1
            redundant_flag = true;
            for j=1:n0
                id = ids(j);
                if stats_new.Volume(id) > minSz && stats_new.Volume(id) < maxSz
                    regCnt = regCnt + 1;
                    regLabelOut(intersect(stats_new.VoxelIdxList{id}, voxIdx)) = regCnt;
                end
            end
        else
            regCnt = regCnt + 1;
            regLabelOut(voxIdx) = regCnt;
        end
    end
    regLabel = regLabelOut;
end