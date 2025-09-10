function Tracking(q)

%% This function is the main function of tracking
% INPUT:
%      data_folder:path of data
%      tmp_path:path of segmentation result
%      save_folder:path of tracking result
%      q:parameters of tracking
% OUTPUT:
%      the output will be stored in save_folder

data_folder = q.data_path;
tmp_path = q.tmp_path;
save_folder = q.result_path;
tps_to_process = q.tps_to_process;
crop_range = q.crop_range;

%% motion flow module
if q.useMotionFlow
    MotionFlowEstimation_stable(data_folder, tmp_path, q);
end

%% define paths
fprintf('--------------------Initial Cell Association--------------------\n');
[tif_files,~] = get_sorted_files(data_folder,tps_to_process);
timepts_to_process = generate_tps_str(tif_files);
cell_seg_res_folder = tmp_path;
refine_res_folder = fullfile(tmp_path, 'InstanceSeg_res');
if ~exist(save_folder,'dir')
    mkdir(save_folder);
end
if ~exist(fullfile(save_folder, 'InstanceSeg_tif'),'dir')
    mkdir(fullfile(save_folder, 'InstanceSeg_tif'));
end
mastodon_dir = fullfile(save_folder, 'mastodon');
if ~exist(mastodon_dir,'dir')
    mkdir(mastodon_dir);
end

%% data preparation
sc_f = q.scaling;        % we resize the data to [h/sc_f, w/sc_f, z, t]
st_loc = q.stLoc;
sz_crop = q.szCrop;

% read data
embryo_vid = cell(numel(tif_files), 1);
for i=1:numel(tif_files)
    embryo_vid_temp{1} = tifread(fullfile(tif_files(i).folder, tif_files(i).name));
    if ~isempty(crop_range)
        embryo_vid_temp{1} = embryo_vid_temp{1}(crop_range(2,1):crop_range(2,2),crop_range(1,1):crop_range(1,2),...
            crop_range(3,1):crop_range(3,2));
    end    
    embryo_vid_temp{1} = 255*embryo_vid_temp{1}./q.scaleTerm;
    [~, embryo_vid_temp, ~, ~, ~] = data_scaling(sc_f, st_loc, ...
    sz_crop, {}, embryo_vid_temp, {}, {}, {});
    if(~all(q.sigma == 0))
        q.sigma = q.sigma + 10^-8;
        embryo_vid{i} = imgaussfilt3(embryo_vid_temp{1},q.sigma);
    else
        embryo_vid{i} = embryo_vid_temp{1};
    end
end
clear embryo_vid_temp

% read segmentation result
file_num = numel(tif_files);
[refine_res, threshold_res] = matfiles2cell_scaling(refine_res_folder, ...
    'refine_res', timepts_to_process, sc_f, st_loc, sz_crop);
if file_num ~= numel(refine_res)
    warning("The number of segmentation results does not equal to number of files!");
end

% read pricinple curvature result
[eig_res_2d, eig_res_3d] = matfiles2cell_scaling(fullfile(cell_seg_res_folder, 'priCvt'), ...
    'priCvt', timepts_to_process, sc_f, st_loc, sz_crop);
eigMaps = cell(file_num,1);
for i=1:file_num
    eigMaps{i} = cell(2,1);
    eigMaps{i}{1} = eig_res_2d{i};
    eigMaps{i}{2} = eig_res_3d{i};
    eig_res_2d{i} = [];
    eig_res_3d{i} = [];
end

%% parameter setting
g = graphPara_cell(sum(cellfun(@(x) max(x(:)), refine_res)));
if length(tps_to_process) <= g.trackLength4var
    g.trackLength4var = 2;
end
g = set_graphPara(g, timepts_to_process, data_folder, tmp_path, q);
q.save_folder = save_folder;
q.img_size = size(embryo_vid{1});
diary(fullfile(save_folder, 'log'));

%% start tracking    
[movieInfo_tem, out_refine_res, threshold_res] = .... 
    mcfTracking_cell(refine_res, embryo_vid, threshold_res, eigMaps, g, q);
movieInfo = AddDivision(embryo_vid, movieInfo_tem, q);

%% save tracking results
save(fullfile(save_folder, 'movieInfo.mat'), 'movieInfo', '-v7.3');
mat2csv(movieInfo, fullfile(save_folder, 'tracking_result.csv'));
if q.saveAllResults
    save(fullfile(save_folder, 'refine_res.mat'), 'out_refine_res','-v7.3');
    save(fullfile(save_folder, 'threshold_res.mat'), 'threshold_res','-v7.3');
end

%% save new segmentation results
if q.saveSegResult
    for i=1:numel(tif_files)
        fprintf('Save segmentation results %d/%d\n', i, numel(tif_files));
        [~, ImName, ~] = fileparts(tif_files(i).name);
        dat = embryo_vid{i};
        dat = 255*dat/q.scaleTerm;
        out_dat = gray2RGB_HD(max(min(dat/255,1),0));
        out_newId = label2RGB_HD(out_refine_res{i});
        out = double(out_dat*0.8 + out_newId*0.5);
        tifPath = fullfile(save_folder, 'InstanceSeg_tif', ImName);
        tifwrite(out, tifPath);
    end
end
fprintf('--------------------Finish Lineage Reconstruction--------------------\n');
%% save tracking results to mastodon
mat2tgmm(movieInfo, fullfile(mastodon_dir, 'tgmm_format'), [sc_f, sc_f, 1]);
tif2bdv(data_folder, fullfile(mastodon_dir, 'embryo_data_h5'), timepts_to_process, st_loc, sz_crop, crop_range);