function seedMap = getSeedMap(dat, PC_max, PC_min, FGmap, BGmap, q)

%% This function is to get seed map based on multi-scale curvature
% INPUT:    
%        dat:input 3D data
%        PC_max:the max 3D curvature
%        PC_min:the min 3D curvature
%        FGmap:the foreground detected by curvature
%        BGmap:the detected foreground
%        q:parameters of segmentation  
% OUTPUT:   
%        seedMap:seed candidate of instances

%% step1 select seed based on min/max curvature map
% the min curvature should be less than curveThres 
% the max curvature should be less than foreThres
fprintf('Start seed selection! \n');
dat = single(dat);
eig_res_3d = PC_min - q.curveThres(q.epoch);
gapMap = PC_max > q.foreThres;
eig_res_3d(gapMap) = max(eig_res_3d(gapMap),1e-3);
%gapMap2 = imdilate(eig_res_3d>0,strel('disk',1));
%eig_res_3d(gapMap2) = max(eig_res_3d(gapMap2),1e-3);

%% step2 split over-merged seeds
CC = bwlabeln(eig_res_3d<0 & ~BGmap,6);
cell_num = max(CC(:));
slices = size(dat,3);
repeatedValues = cell(slices,1);
for i = 1:slices
    CC_tem = bwconncomp(CC(:,:,i),4);
    pixelValues = regionprops(CC_tem, CC(:,:,i), 'PixelValues');  
    id_tem = nan(CC_tem.NumObjects,1);
    for j = 1:CC_tem.NumObjects
        id_tem(j) = unique(pixelValues(j).PixelValues);
    end
    [uniqueValues, ~, idx] = unique(id_tem);
    counts = histcounts(idx, 1:length(uniqueValues)+1);
    repeatedValues{i} = uniqueValues(counts > 1);
end
repeatedValues = cell2mat(repeatedValues);
repeat_num = length(repeatedValues);
loc_cells = cell(repeat_num,1);
for i = 1:repeat_num
    seed_candidate = CC == repeatedValues(i);
    comMaps = get_local_area_seed(seed_candidate,q.shift);
    [~,~,m] = ind2sub(size(comMaps.idComp),find(comMaps.idComp));
    slice = unique(m);         
    num_slices = numel(slice);
    % obtain connected regions on each z-slice
    multi_flag = false;
    for z = 1:num_slices
        CC_2d = bwlabeln(comMaps.idComp(:,:,slice(z)),4);
        if max(CC_2d(:))>1
            multi_flag = true;
            break;
        end
    end
    if ~multi_flag || num_slices<=1
        continue;
    end
    obj_num = 0;  
    obj_pos = cell(num_slices*3,2);
    obj_slice = nan(num_slices*3,1);
    for z = 1:num_slices
        CC_2d = bwlabeln(comMaps.idComp(:,:,slice(z)),4);
        for j = 1:max(CC_2d(:))
            obj_num = obj_num + 1;
            [coord_x, coord_y] = find(CC_2d == j);
            obj_pos{obj_num,1} = sub2ind(size(CC_2d),coord_x,coord_y);
            obj_pos{obj_num,2} = [coord_x,coord_y];
            obj_slice(obj_num) = slice(z);
        end
    end    
    if obj_num == num_slices
        continue;
    end
    obj_pos = obj_pos(1:obj_num,:);
    obj_slice = obj_slice(1:obj_num);

    % build graph for over-merged seed 
    groups = arrayfun(@(z) find(obj_slice==z), slice, 'UniformOutput',false);    
    edge_list = []; 
    for z = 1:num_slices-1
        prev = groups{z}; 
        next = groups{z+1};
        if isempty(prev) || isempty(next)
            continue; 
        end              
        [s,d] = ndgrid(prev, next);
        edge_list = [edge_list; [s(:),d(:)]];
    end
    edge_num = size(edge_list,1);
    for j = 1:edge_num
        overlap = length(intersect(obj_pos{edge_list(j,1),1},obj_pos{edge_list(j,2),1}))/...
            min(length(obj_pos{edge_list(j,1),1}),length(obj_pos{edge_list(j,2),1}));
        edge_list(j,3) = overlap;
    end

    % select correct path(prefer bigger overlap)
    pick_id = nan(size(edge_list,1),2);
    pick_num = 0;
    for j = 1:num_slices-1
        last_id = find(obj_slice == slice(j));
        for xx = 1:length(last_id)
            edge_id = find(edge_list(:,1)==last_id(xx));
            overlap_tem = edge_list(edge_id,3);
            [~,max_id] = max(overlap_tem);
            pick_num = pick_num + 1;
            pick_id(pick_num,1) = edge_id(max_id);
        end
    end
    pick_num = 0;
    for j = num_slices:-1:2
        last_id = find(obj_slice == slice(j));
        for xx = 1:length(last_id)
            edge_id = find(edge_list(:,2)==last_id(xx));
            overlap_tem = edge_list(edge_id,3);
            [~,max_id] = max(overlap_tem);
            pick_num = pick_num + 1;
            pick_id(pick_num,2) = edge_id(max_id);
        end
    end
    pick_id = intersect(pick_id(~isnan(pick_id(:,1)),1),pick_id(~isnan(pick_id(:,2)),2));
   
    % transfer to 3D coord
    edge_list_valid = edge_list(pick_id,1:2);

    nodes = unique(edge_list_valid(:));            
    n = length(nodes);
    parent = 1:n;                      
    nodeMap = containers.Map(nodes, 1:n); 
    
    for j = 1:size(edge_list_valid,1)
        a = edge_list_valid(j,1); 
        b = edge_list_valid(j,2);
        idxA = nodeMap(a); 
        idxB = nodeMap(b);
        while parent(idxA) ~= idxA
            idxA = parent(idxA); 
        end
        while parent(idxB) ~= idxB
            idxB = parent(idxB);
        end
        if idxA ~= idxB
            parent(parent == idxB) = idxA; 
        end
    end
    
    [~, ~, groupIds] = unique(parent);
    groups = arrayfun(@(k) nodes(groupIds == k)', unique(groupIds, 'stable'), 'Uni',0);

    for j = 1:numel(groups)
        new_region_xy = obj_pos(groups{j},2);
        new_region_z = obj_slice(groups{j});
        new_update_coord = cell(length(new_region_z),1);
        for k = 1:length(new_region_z)
            change_id = [new_region_xy{k},ones(size(new_region_xy{k},1),1)*new_region_z(k)];
            new_update_coord{k} = comMaps.linerInd(sub2ind(size(comMaps.idComp),...
                change_id(:,1),change_id(:,2),change_id(:,3)));
        end
        new_update_coord = cell2mat(new_update_coord);
        loc_cells{i}{j} = new_update_coord;
    end
end
new_cell_num = cell_num;
for i = 1:repeat_num
    cell_id = repeatedValues(i);
    if ~isempty(loc_cells{i})
        CC(CC==cell_id) = 0;
        split_num = numel(loc_cells{i});
        CC(loc_cells{i}{1}) = cell_id;
        if split_num > 1
            for  j = 2:split_num
                new_cell_num = new_cell_num + 1;
                CC(loc_cells{i}{j}) = new_cell_num;
            end
        end
    end
end

%% step3 test size and intensity
seedMap = zeros(size(dat));
s = regionprops3(CC, {'VoxelIdxList'});
k = 0;
for i = 1:numel(s.VoxelIdxList)
    idx = s.VoxelIdxList{i};
    if mean(dat(idx))>q.bgIntensity_scaling && any(FGmap(idx))
        k = k+1;
        seedMap(idx) = k;
    end
end