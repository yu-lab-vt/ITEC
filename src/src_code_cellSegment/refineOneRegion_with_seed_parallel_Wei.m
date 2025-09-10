function [newLabel, comMaps] = refineOneRegion_with_seed_parallel_Wei(seed_id, comMaps, q)

%% This function is to refine the seed region indicate by index in yxz
% NOTE: it is possible the yxz is not exactly the same as seed_id label
% indicates, e.g. the seed is relabeled. We view yxz as the correct one.
% INPUT:
%      comMaps: the local information of instances
%      seed_id: the id we focus on
%      q: parameters of segmentation
% OUTPUT:
%      newLabel: the new foreground
%      comMaps: the local information of instances

%% step1:boundary refine based on min cut
strel_rad = q.shift;
max_pv = max(comMaps.score3dMap(:));
comMaps.score3dMap = comMaps.score3dMap - q.curveThres(q.epoch);
comMaps.score3dMap = comMaps.score3dMap/max_pv;

max_pv2 = max(comMaps.score2dMap(:));
comMaps.score2dMap = comMaps.score2dMap - q.curveThres(q.epoch);
max_region = comMaps.score2dMap < 0;
comMaps.score2dMap = comMaps.score2dMap/max_pv2;

comMaps.scoreMap = (comMaps.score3dMap + comMaps.score2dMap * 2)/3;
comMaps.scoreMap(comMaps.scoreMap<0) = 0;
comMaps.scoreMap = scale_image(comMaps.scoreMap, 1e-3,1, 0, max(comMaps.scoreMap(:)));
strel_ker = getKernel(strel_rad);
fMap = comMaps.regComp;
fMap = imdilate(fMap,strel_ker);

sph = strel('sphere', 2);
se = strel(sph.Neighborhood(:,:,3));      % equal to strel('disk',2)
otherIdTerritory = comMaps.idComp ~= seed_id & comMaps.idComp > 0;
otherIdTerritory = imdilate(otherIdTerritory, se);
fMap(otherIdTerritory) = 0;

%fMap((comMaps.idComp ~= seed_id) & (comMaps.idComp > 0)) = 0;
com = bwconncomp(comMaps.newIdComp);
newLabel = zeros(size(fMap));
for ii = 1:com.NumObjects
    sMap = false(size(fMap));
    sMap(com.PixelIdxList{ii}) = true;
    tMap = true(size(fMap));
    tMap(fMap) = false;
    tMap(comMaps.newIdComp) = true;
    tMap(com.PixelIdxList{ii}) = false;

    scoreMap = comMaps.scoreMap; 
    scoreMap(scoreMap<0) = 0;
    [dat_in, src, sink] = graphCut_negHandle_mat(scoreMap, fMap, sMap, ...
        tMap, 10, [1 1], true);       % before fusion
    G = digraph(dat_in(:,1),dat_in(:,2),dat_in(:,3));
    if ~isempty(find(isnan(dat_in(:)), 1)) || isnan(sink)
        continue;
    end
    [~,~,cs,~] = maxflow(G, src, sink);         % cs: fg, ct: bg
    cs = cs(cs<=numel(newLabel));

    cur_l = newLabel(cs);
    if length(unique(cur_l))>2
        keyboard;
    end
    newLabel(cs) = ii;
end

%% step2 remove fp slices and add new slices
slices = size(newLabel,3);
[~,~,m] = ind2sub(size(newLabel),find(newLabel));
for i = 1:slices
    if nnz(sMap(:,:,i)) == 0 && nnz(newLabel(:,:,i))~=0
        % the new region must be 2d seed
        if nnz(max_region(:,:,i) & newLabel(:,:,i)) == 0
            newLabel(:,:,i) = 0;
        end
    end
end
if q.addslice
    if min(m) ~= 1
        [newLabel,~] = add_slice(comMaps,newLabel,min(m),-1);
    end
    if max(m) ~= slices
        [newLabel,~] = add_slice(comMaps,newLabel,max(m),1);
    end
end

%% step3 test if the cell is true
se0 = strel('disk',2);
se1 = strel('disk',6);
FG = comMaps.vidComp(find(newLabel));
BGmap0 = imdilate(newLabel,se0);
BGmap_unreliable = imdilate(comMaps.idComp>0,se0);
BGmap = imdilate(newLabel,se1) & ~BGmap_unreliable & ~BGmap0;
BG = comMaps.vidComp(BGmap);
if mean(FG)-mean(BG)<q.diffIntensity
    newLabel = false(size(newLabel));
end
end