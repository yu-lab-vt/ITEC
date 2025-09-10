function [newLabel,addflag] = add_slice(comMaps,newLabel,mslice,dir_flag)

%% This function is designed to make up for missing slices in segmentation
% INPUT:
%      comMaps: the local information of instances
%      newLabel: the detected foreground
%      mslice: slice index at the foreground edge
%      dir_flag: possible directions for adding slices, 1 forward and -1 backward
% OUTPUT:
%      newLabel: the new foreground
%      addflag: flag indicating if we add new slices

max_region = comMaps.score2dMap<0;
addflag = false;
next_region = max_region(:,:,mslice+dir_flag);
% determine whether a new slice should be added
if any(next_region(:))
    tem_region = logical(newLabel(:,:,mslice));
    L = bwlabeln(next_region);
    overlap_counts = accumarray(L(tem_region)+1,1);
    overlap_counts(1) = 0;  
    [~, max_label] = max(overlap_counts); 
    next_region = L == max_label-1;
    overlap_ratio = nnz(tem_region&next_region)/nnz(next_region);
    % there should be 2D seed and the 2D seed should overlap with 3D projection
    if overlap_ratio >= 0.9
        next_region = tem_region & next_region;
        next_intensity = comMaps.vidComp(:,:,mslice+dir_flag);
        tem_intensity = comMaps.vidComp(:,:,mslice);
        % the new seed region should be darker and not too small
        if mean(next_intensity(next_region)) < mean(tem_intensity(tem_region))...
                && nnz(next_region)/nnz(tem_region)>0.2
            addflag = true;
        end
    end
end

% 2D seed growth for new seed region
if addflag
    sMap = next_region;
    tMap = ~imdilate(tem_region,strel('disk',5));
    scoreMap = comMaps.score2dMap(:,:,mslice+dir_flag);
    scoreMap(scoreMap<0) = 0;
    scoreMap = scale_image(scoreMap, 1e-3,1, 0, max(scoreMap(:)));
    fMap = ~sMap & ~tMap;
    [dat_in, src, sink] = graphCut_negHandle_mat(scoreMap, fMap, sMap, ...
        tMap, 8, [1 1], true);       % before fusion
    G = digraph(dat_in(:,1),dat_in(:,2),dat_in(:,3));
    if isempty(find(isnan(dat_in(:)), 1)) && ~isnan(sink)
        newLabel_tem = false(size(next_region));
        [~,~,cs,~] = maxflow(G, src, sink); % cs: fg, ct: bg
        cs = cs(cs<=numel(newLabel_tem));
        newLabel_tem(cs) = true;
        se0 = strel('disk',2);
        se1 = strel('disk',6);
        FG = next_intensity((newLabel_tem));
        BGmap0 = imdilate(newLabel_tem,se0);
        BGmap_unreliable = imdilate(comMaps.idComp(:,:,mslice+dir_flag)>0,se0);
        BGmap = imdilate(newLabel_tem,se1) & ~BGmap_unreliable & ~BGmap0;
        BG = next_intensity(BGmap);
        if (mean(FG)-mean(BG))>0.1*(mean(tem_intensity(tem_region)-mean(BG)))
            newLabel(:,:,mslice+dir_flag) = newLabel_tem & tem_region;
        end
    end
end