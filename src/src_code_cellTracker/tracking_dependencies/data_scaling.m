function [refine_res, embryo_vid, gt_mat, threshold_res, ...
    eigMaps] = data_scaling(sc_f, st_loc, sz_crop, refine_res, ...
    embryo_vid, gt_mat_org, threshold_res, eigMaps)
% scaling the data and/or crop a sub region
if ~isempty(st_loc)
    h = sz_crop(1);
    w = sz_crop(2);
    z = sz_crop(3);
    end_loc = st_loc + sz_crop - 1;
else
    if ~isempty(refine_res)
        [h, w, z] = size(refine_res{1});
    elseif ~isempty(embryo_vid)
        [h, w, z] = size(embryo_vid{1});
    elseif ~isempty(threshold_res)
        [h, w, z] = size(threshold_res{1});
    elseif ~isempty(eigMaps)
        [h, w, z] = size(eigMaps{1}{1});
    else
        error('must have at least one valid input');
    end
end

% general case
ds_sz = round([h/sc_f, w/sc_f, z]);
num_files = 0;
if ~isempty(refine_res)
    num_files = numel(refine_res);
elseif ~isempty(embryo_vid)
    num_files = numel(embryo_vid);
elseif ~isempty(threshold_res)
    num_files = numel(threshold_res);
elseif ~isempty(eigMaps)
    num_files = numel(eigMaps);
else
    error('must have at least one valid input');
end

gt_mat = gt_mat_org;
if sc_f == 1
    return;
end
for i = 1:num_files
    if ~isempty(st_loc)
        if ~isempty(refine_res)% refactor all these ifs
            refine_res{i} = refine_res{i}(st_loc(1):end_loc(1), ...
                st_loc(2):end_loc(2),st_loc(3):end_loc(3));
            refine_res{i} = rearrange_id(refine_res{i});
        end
        if ~isempty(embryo_vid)
            embryo_vid{i} = embryo_vid{i}(st_loc(1):end_loc(1), ...
                st_loc(2):end_loc(2),st_loc(3):end_loc(3));
        end
        if ~isempty(threshold_res)
            threshold_res{i} = threshold_res{i}(st_loc(1):end_loc(1), ...
                st_loc(2):end_loc(2),st_loc(3):end_loc(3));
        end
        if ~isempty(eigMaps)
            eigMaps{i}{1} = eigMaps{i}{1}(st_loc(1):end_loc(1), ...
                st_loc(2):end_loc(2),st_loc(3):end_loc(3));
            eigMaps{i}{2} = eigMaps{i}{2}(st_loc(1):end_loc(1), ...
                st_loc(2):end_loc(2),st_loc(3):end_loc(3));
        end
    end
    if ~isempty(refine_res)
        refine_res{i} = imresize3(refine_res{i},ds_sz,'method','nearest');
    end
    if ~isempty(embryo_vid)
        embryo_vid{i} = imresize3(embryo_vid{i},ds_sz,'method','nearest');
    end
    if ~isempty(threshold_res)
        threshold_res{i} = imresize3(threshold_res{i},ds_sz,'method','nearest');
    end
    if ~isempty(eigMaps)
        eigMaps{i}{1}(isnan(eigMaps{i}{1})) = 0;
        eigMaps{i}{2}(isnan(eigMaps{i}{2})) = 0;
        eigMaps{i}{1} = imresize3(eigMaps{i}{1},ds_sz,'method','cubic');
        eigMaps{i}{2} = imresize3(eigMaps{i}{2},ds_sz,'method','cubic');
    end
end

for i=1:numel(gt_mat)
    if ~isempty(st_loc)
        y_v = gt_mat{i}(:,2)>=st_loc(1) & gt_mat{i}(:,2)<=end_loc(1);
        x_v = gt_mat{i}(:,3)>=st_loc(2) & gt_mat{i}(:,3)<=end_loc(2);
        z_v = gt_mat{i}(:,4)>=st_loc(3) & gt_mat{i}(:,4)<=end_loc(3);
        v_ = y_v & x_v & z_v;
        [lmap, n] = bwlabeln(v_);
        if n==0
            gt_mat{i} = [];
            continue;
        end
        s = regionprops(lmap,'Area');
        [~, od] = max([s.Area]);
        gt_mat{i} = gt_mat{i}(lmap==od,:);
        gt_mat{i}(:,2) = gt_mat{i}(:,2) - st_loc(1) + 1;
        gt_mat{i}(:,3) = gt_mat{i}(:,3) - st_loc(2) + 1;
        gt_mat{i}(:,4) = gt_mat{i}(:,4) - st_loc(3) + 1;
    end
    
    gt_mat{i}(:,2:4) = gt_mat{i}(:,2:4).*(ds_sz./[h,w,z]);

end
le = cellfun(@length, gt_mat);
gt_mat = gt_mat(le>0);
end