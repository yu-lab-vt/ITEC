function [newIdMap,thresholdMap]=boundaryRefineModule(idMap,eig3d,eig2d,vid, q)

%% This function is to refine boundary of seed candidate
% INPUT:    
%        idMap: seed candidate of instances
%        eig3d: the 3D curvature used for boundary refine
%        eig2d: the 2D curvature used for boundary refine
%        vid: the input 3D data
%        q:parameters of segmentation  
% OUTPUT:   
%        newIdMap: detected regions with each region one unique id
%        thresholdMap: median intensity of detected regions

%% step1 test the size of seeds
idMap_current = idMap;
[idMap2, redundant_flag] = region_sanity_check(idMap_current, q.minSeedSize, q.maxSeedSize); % remove small objects
if redundant_flag
    idMap_current = idMap2;
end
s = regionprops3(idMap_current, {'VoxelIdxList'});
% process from brightest seed to dimmest ones
seed_levels = cellfun(@(x) mean(vid(x)), s.VoxelIdxList);
[~, seed_proc_order] = sort(seed_levels,'descend');

%% step2 start to crop local region
loc_cells = cell(numel(s.VoxelIdxList),1);
comMaps = cell(numel(s.VoxelIdxList),1);
for ii=1:numel(s.VoxelIdxList)
    % crop needed information
    seed_id = seed_proc_order(ii);
    yxz = s.VoxelIdxList{seed_id};
    ids = idMap_current(yxz);
    yxz = yxz(ids==seed_id);
    comMaps{ii} = get_local_area_Wei(vid,idMap_current,seed_id,eig3d,eig2d,yxz,q.shift);   % zqh 
end

%% step3 start boundary refine
parfor i=1:numel(s.VoxelIdxList)
    seed_id = seed_proc_order(i);
    [newLabel, comMaps_temp] = refineOneRegion_with_seed_parallel_Wei(seed_id, comMaps{i},q);
    valid_newLabel = newLabel(:)>0;
    loc_cells{i} = cell(2,1);
    loc_cells{i}{1} = [comMaps_temp.linerInd(valid_newLabel), newLabel(valid_newLabel)];
    loc_cells{i}{2} = round(quantile(comMaps_temp.vidComp(valid_newLabel),0.5)); 
end

%% step4 deal with conflicts
newIdMap = zeros(size(idMap_current));
thresholdMap = zeros(size(idMap_current));
regCnt = 0;
[h,w,~] = size(vid);
for i = 1:numel(loc_cells)
    if ~isempty(loc_cells{i}{1})
        cur_locs = loc_cells{i}{1}(:,1);
        cur_labels = loc_cells{i}{1}(:,2);
        other_id = setdiff(unique(newIdMap(cur_locs)),0);
        for j = 1:length(other_id)
            other_id_tem = other_id(j);
            other_loc = cur_locs((newIdMap(cur_locs)==other_id_tem));
            other_label = cur_labels((newIdMap(cur_locs)==other_id_tem));
            [~,~,both_slice] = ind2sub(size(vid),other_loc);
            both_slice_unique = unique(both_slice);
            for k = 1:length(both_slice_unique)
                slice_tem = both_slice_unique(k);
                loc1 = find(newIdMap(:,:,slice_tem)==other_id_tem)+(slice_tem-1)*h*w;
                loc2 = cur_locs(cur_locs>(slice_tem-1)*h*w & cur_locs<=(slice_tem)*h*w);
                if length(other_loc)/length(loc1)>0.6 & length(other_loc)/length(loc2)<0.6 & ~all(ismember(loc1,loc2))
                    cur_locs = setdiff(cur_locs,loc1);
                elseif length(other_loc)/length(loc1)<0.6 & length(other_loc)/length(loc2)>0.6 & all(ismember(loc2,loc1))
                    cur_locs = setdiff(cur_locs,loc2);
                elseif length(other_loc)/length(loc1)>0.6 & length(other_loc)/length(loc2)>0.6
                    if mean(vid(loc1))>mean(vid(loc2))
                        cur_locs = setdiff(cur_locs,loc2);
                    else
                        cur_locs = union(cur_locs,loc1);
                    end
                end
            end
            if length(cur_locs)>length(cur_labels)
                cur_labels = [cur_labels;other_label(1) * ...
                ones(length(cur_locs)-length(cur_labels),1)];
            elseif length(cur_locs)<length(cur_labels)
                cur_labels = cur_labels(1)*ones(length(cur_locs),1);
            end
        end
        if ~isempty(cur_labels)
            newIdMap(cur_locs) = cur_labels + regCnt;
            thresholdMap(cur_locs) = loc_cells{i}{2};
            regCnt = regCnt + max(cur_labels);
        end
    end
end