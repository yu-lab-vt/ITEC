function regVoxIdx = bisectRegion_gapguided(root_voxIdx, root_frame, ...
    base_voxIdx, vidMap, refine_res, eigMaps, validGapMaps, q)
% test if 
% 1. there is a gap defined by principal curvature
% 2. the gap separate the root region into two regions consistent with
% the TWO regions defined by base_voxIdx

% If the two criterions are both satisfied, we separate the root region
% into two regions, otherwise return empty elements

if numel(base_voxIdx) ~= 2 || ~isempty(find(cellfun(@isempty, base_voxIdx),1))% split into two regions
    regVoxIdx = cell(2,1);
    return;
end

yxz = union(root_voxIdx, cat(1, base_voxIdx{:}));
% crop regions
[idComp, linerInd, ~, loc_org_xyz] = crop3D(refine_res{root_frame}, ...
    yxz, q.shift);

% 2d principal curvature
eig2dComp = crop3D(eigMaps{root_frame}{1}, yxz, q.shift);
possibleGaps2d = eig2dComp>0;
eig2dComp(eig2dComp<0) = 0;
min_pv = 0;%min(eigMaps{root_frame}{1}(root_voxIdx));
max_pv = max(eigMaps{root_frame}{1}(root_voxIdx));
eig2dComp = scale_image(eig2dComp, 1e-3,1, min_pv, max_pv);
eig2dComp(isnan(eig2dComp)) = 0;


% 3d principal curvature
eig3dComp = crop3D(eigMaps{root_frame}{2}, yxz, q.shift);
possibleGaps3d = eig3dComp>0;
eig3dComp(eig3dComp<0) = 0;
min_pv = 0;
max_pv = max(eigMaps{root_frame}{2}(root_voxIdx));
eig3dComp(isnan(eig3dComp)) = 0;
eig3dComp = scale_image(eig3dComp, 1e-3,1, min_pv, max_pv);
if ~isempty(validGapMaps)
    gapComp = crop3D(validGapMaps{root_frame}, yxz, q.shift);
    possibleGaps2d = possibleGaps2d & gapComp;
    possibleGaps3d = possibleGaps3d & gapComp;
end
% [vidComp, linerInd, ~, loc_org_xyz] = crop3D(vidMap{root_frame}, yxz, ...
%     q.shift);

% build valid label map
real_id = refine_res{root_frame}(root_voxIdx(1));
base_idx_local = coordinate_transfer(base_voxIdx, ...
    size(refine_res{root_frame}), loc_org_xyz, size(idComp));
[label_map_binary, vflag] = binary_seeds_create(idComp==real_id, ...
    possibleGaps3d, [], base_idx_local);%, q.minSeedSize
if ~vflag % if 3d cannot detect gaps, we change to 2d gaps
    [label_map_binary, vflag] = binary_seeds_create(idComp==real_id, ...
        [], possibleGaps2d, base_idx_local);
    if ~vflag % indeed we can still increase treshold, but do we need?
        regVoxIdx = cell(2,1);
        return;
    end
end


%% region grow the regions from label_map_binary
fMap = idComp == real_id;
new_l = zeros(size(fMap));
scoreMap = eig2dComp + eig3dComp;
regVoxIdx = cell(numel(base_voxIdx), 1);
for i=1:numel(base_voxIdx)
    sMap = label_map_binary == i;
    tMap = label_map_binary>0;
    tMap(sMap) = false;
    [dat_in, src, sink] = graphCut_negHandle_mat(scoreMap, fMap, sMap, tMap, ...
        q.growConnectInRefine, q.cost_design, false);
    % if src/sink cannot be linked in the foreground, return
    if isempty(find(dat_in(:,1) == src,1)) || ...
            isempty(find(dat_in(:,2) == sink,1))
        regVoxIdx = cell(2,1);
        return;
    end
    G = digraph(dat_in(:,1),dat_in(:,2),dat_in(:,3));
    [~,~,cs,~] = maxflow(G, src, sink); % cs: fg, ct: bg
    reg_locs = cs(cs<numel(fMap));
    regVoxIdx{i} = linerInd(reg_locs);
    
    new_l(reg_locs) = i;
end
end