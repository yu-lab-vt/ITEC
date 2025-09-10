function regVoxIdx = bisectRegion(root_voxIdx, root_frame, ...
    base_voxIdx, base_frame, vidMap, refine_res, eigMaps, validGapMaps, q)
% separate current region (root_voxIdx) into two splitted regions
% This is based on the intersections of base regions and current region. We
% also remove gaps if this does not make intersections empty
if numel(base_voxIdx) ~= 2 || ~isempty(find(cellfun(@isempty, base_voxIdx),1))% split into two regions
    regVoxIdx = cell(2,1);
    return;
end
% graph-cut to separate current cell region into multiple regions
yxz = union(root_voxIdx, cat(1, base_voxIdx{:}));
% crop regions
[idComp, linerInd, ~, loc_org_xyz] = crop3D(refine_res{root_frame}, yxz, q.shift);
eig2dComp = crop3D(eigMaps{root_frame}{1}, yxz, q.shift);
eig2dComp(eig2dComp<0) = 0;
min_pv = 0;
max_pv = max(eigMaps{root_frame}{1}(root_voxIdx));
eig2dComp = scale_image(eig2dComp, 1e-3,1, min_pv, max_pv);
eig2dComp(isnan(eig2dComp)) = 0;

eig3dComp = crop3D(eigMaps{root_frame}{2}, yxz, q.shift);
possibleGaps = eig3dComp>0;
if ~isempty(validGapMaps)
    gapComp = crop3D(validGapMaps{root_frame}, yxz, q.shift);
    possibleGaps = possibleGaps & gapComp;
end
eig3dComp(eig3dComp<0) = 0;
min_pv = 0;
max_pv = max(eigMaps{root_frame}{2}(root_voxIdx));
eig3dComp = scale_image(eig3dComp, 1e-3,1, min_pv, max_pv);
eig3dComp(isnan(eig3dComp)) = 0;

scoreMap = eig2dComp + eig3dComp;


% base_centers = cell(numel(base_voxIdx), 1); % label current region
% refine seed region 1 round
base_centers = seedRefine_intensity(vidMap, root_voxIdx, root_frame, ...
    base_voxIdx, base_frame);
base_sz = cellfun(@length, base_centers);
if ~isempty(find(base_sz==0,1))
    regVoxIdx = cell(2,1);
    return;
end
for j=1:numel(base_centers)
    [y, x, z] = ind2sub(size(refine_res{root_frame}), base_centers{j});
    base_centers{j} = [x, y, z];
    base_centers{j} = base_centers{j} - (loc_org_xyz-1);
    base_centers{j} = sub2ind(size(idComp), base_centers{j}(:,2), ...
        base_centers{j}(:,1), base_centers{j}(:,3));
    % remove seed voxels that locate on gaps
    seedReg = false(size(possibleGaps));
    seedReg(base_centers{j}) = true;
    % refine seed region 2nd round
    seedReg = seedRefine_gap(possibleGaps, seedReg);
    tmp_idx = find(seedReg);
    if ~isempty(tmp_idx)
        base_centers{j} = tmp_idx;
    else
        fprintf('we find a seed all on gaps!\n');
    end
end
base_sz = cellfun(@length, base_centers);
if ~isempty(find(base_sz==0,1))
    regVoxIdx = cell(2,1);
    return;
end

[y, x, z] = ind2sub(size(refine_res{root_frame}), root_voxIdx);
fg_idx = [x, y, z] - (loc_org_xyz-1);
fg_idx = sub2ind(size(idComp), fg_idx(:,2), fg_idx(:,1), fg_idx(:,3));
fMap = false(size(idComp));
fMap(fg_idx) = true;

regVoxIdx = cell(numel(base_centers), 1);
allIdMap = false(size(fMap));
allIdMap(cat(1, base_centers{:})) = true;
for i=1:numel(base_centers)
    sMap = false(size(fMap));
    sMap(base_centers{i}) = true;
    tMap = allIdMap;
    tMap(sMap) = false;
    
    [dat_in, src, sink] = graphCut_negHandle_mat(scoreMap, fMap, sMap, tMap, ...
        q.growConnectInRefine, q.cost_design, false);
    if isnan(sink)
        regVoxIdx = cell(2,1);
        break;
    end
    G = digraph(dat_in(:,1),dat_in(:,2),dat_in(:,3));
    [~,~,cs,~] = maxflow(G, src, sink); % cs: fg, ct: bg
    reg_locs = cs(cs<numel(fMap));
    regVoxIdx{i} = linerInd(reg_locs);
end
end