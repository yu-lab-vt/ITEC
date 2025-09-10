function [newLabel, comMaps] = refineOneRegion_with_seed(seed_id, comMaps, q)

%% This function is specifically designed for refining cell with seed in missing cell module

% NOTE: it is possible the yxz is not exactly the same as seed_id label
% indicates, e.g. the seed is relabeled. We view yxz as the correct one.

%% gap detection based on min cut
strel_ker = getKernel(q.shift);
max_pv = max(comMaps.score3dMap(:));
comMaps.score3dMap = comMaps.score3dMap - q.curveThres(end);
comMaps.score3dMap(comMaps.score3dMap<0) = 0;
comMaps.score3dMap = scale_image(comMaps.score3dMap, 1e-3,1, 0, max_pv);

fMap = comMaps.regComp;
fMap = imdilate(fMap,strel_ker);
sph = strel('sphere', 2);
se = strel(sph.Neighborhood(:,:,3));% equal to strel('disk',2)
otherIdTerritory = comMaps.idComp>0 & comMaps.regComp==0;
otherIdTerritory = imdilate(otherIdTerritory, se);
otherIdTerritory(comMaps.regComp>0) = 0;
fMap(otherIdTerritory) = 0;

sMap = comMaps.regComp;
tMap = true(size(fMap));
tMap(fMap) = false;
tMap(sMap) = false;  

newLabel = false(size(fMap));
if isempty(find(fMap,1)) || size(find(tMap),1)<q.minSeedSize || ...
        size(find(sMap),1)<q.minSeedSize
    return;
end

scoreMap = comMaps.score3dMap; 
scoreMap(scoreMap<0) = 0;
[dat_in, src, sink] = graphCut_negHandle_mat(scoreMap, fMap, sMap, ...
        tMap, 10, [1 1], true); 
if isnan(sink)
    return;
end    
G = digraph(dat_in(:,1),dat_in(:,2),dat_in(:,3));
[~,~,cs,~] = maxflow(G, src, sink); 
cs = cs(cs<=numel(newLabel));
cur_l = newLabel(cs);
if length(unique(cur_l))>2
    keyboard;
end
newLabel(cs) = true;

%% refine again and test if the cell is too small
l = bwlabeln(newLabel, 6);
seed_ids = l(comMaps.regComp>0);
seed_ids = mode(seed_ids(seed_ids>0));       % we should only keep the best connected component
newLabel = ismember(l, seed_ids);
newLabel = bwareaopen(newLabel, q.minSize, 26);

%% test if our new cell is consistent with the original seeds
init_seed_num = nnz(comMaps.init_seed_map);
ov_ratio = nnz(comMaps.init_seed_map & newLabel)/init_seed_num;
if ov_ratio >= 0.2
    comMaps.fmapComp = logical(newLabel);
    comMaps.idComp(comMaps.idComp == seed_id) = 0;
    comMaps.idComp(find(newLabel)) = seed_id;
else
    newLabel = false(size(newLabel));
end

end
