function InstanceSegmentation(q)

%% This function is the main function for cell segmentation
% INPUT:
%      data_path:path of data
%      tmp_path:path of segmentation result
%      q:parameters of segmentation
% OUTPUT:
%      the output will be stored in tmp_path

%% generate folder
data_path = q.data_path;
tmp_path = q.tmp_path;
if ~exist(tmp_path,'dir')
    mkdir(tmp_path);
end
if ~exist(fullfile(tmp_path, 'InstanceSeg_res'),'dir')
    mkdir(fullfile(tmp_path, 'InstanceSeg_res'));
end
if ~exist(fullfile(tmp_path, 'priCvt'),'dir')
    mkdir(fullfile(tmp_path, 'priCvt'));
end
if ~exist(fullfile(tmp_path, 'InstanceSeg_tif'),'dir') && q.visualization
    mkdir(fullfile(tmp_path, 'InstanceSeg_tif'));
end

%% parameter setting
tps_to_process = q.tps_to_process;
crop_range = q.crop_range;
[tif_files,~] = get_sorted_files(data_path,tps_to_process);
for i = 1:numel(tif_files)
    %% step1: load data and pre-processing
    fprintf('Instance segmentation processing %d/%d\n', i, numel(tif_files));
    tic;
    org_im = tifread(fullfile(tif_files(i).folder, tif_files(i).name));
    if ~isempty(crop_range)
        org_im = org_im(crop_range(2,1):crop_range(2,2),crop_range(1,1):crop_range(1,2),...
            crop_range(3,1):crop_range(3,2));
    end
    [~, org_name, ~] = fileparts(tif_files(i).name);
    org_im(org_im > q.scaleTerm) = q.scaleTerm;
    org_im(org_im < q.clipping) = q.clipping;
    org_im = single(255*(org_im-q.clipping)/(q.scaleTerm-q.clipping));
    q.bgIntensity_scaling = 255*(q.bgIntensity-q.clipping)/(q.scaleTerm-q.clipping);
    [h, w, slices] = size(org_im);
    org_im2 = imresize3(org_im,round([h/q.downSampleScale w/q.downSampleScale slices]));
    if(~all(q.sigma == 0))
        q.sigma = q.sigma + 10^-8;
        sm_im = imgaussfilt3(org_im2,q.sigma);
    else 
        sm_im = org_im2;
    end

    %% step2: calculate curvature  
    % step2.1 estimate the std of noise
    if ~exist('g','var')
        g = [];
    end
    [q,g] = varEst(sm_im,q,g);
    % step2.2 get curvature
    if q.boundaryDetect
        sm_im = cat(3,sm_im(:,:,1)*0.8,sm_im,sm_im(:,:,end)*0.8);
    end
    [curvature_3D_max,curvature_3D_min,curvature_3D_bdary,curvature_2D_bdary,...
        ~,FGmap] = PrcplCrvtr_scaleInvariant_3D(sm_im, q, g);

    %% step3: instance segmentation
    refine_res = zeros(size(sm_im));
    threshold_res = zeros(size(sm_im));
    cell_num = 0;
    epoch_num = length(q.curveThres);
    for epoch = 1:epoch_num
        % step3.1 select seed
        BGmap = refine_res;
        q.epoch = epoch;
        seedMap = getSeedMap(sm_im, curvature_3D_max, curvature_3D_min, FGmap, BGmap, q);
        
        % step3.2 boundary refine
        [refine_res_tem,threshold_res_tem] = regionWiseAnalysis4d_Wei10(seedMap,...
                             curvature_3D_bdary,curvature_2D_bdary,sm_im,q);
        refine_res(refine_res_tem~=0) = refine_res_tem(refine_res_tem~=0) + cell_num;
        threshold_res(threshold_res_tem~=0) = threshold_res_tem(threshold_res_tem~=0);
        cell_num = cell_num + max(refine_res_tem(:));
    end
    if q.boundaryDetect
        refine_res = refine_res(:,:,2:end-1);
        threshold_res = threshold_res(:,:,2:end-1);
        curvature_3D_bdary = curvature_3D_bdary(:,:,2:end-1);
        curvature_2D_bdary = curvature_2D_bdary(:,:,2:end-1);
    end
    refine_res = rearrange_id(refine_res);
    refine_res = uint32(refine_res);
    threshold_res = uint8(threshold_res);
    
    % step3.3 save results
    if isempty(find(refine_res,1))
        warning('No cells were detected!');
    end
    refine_res = imresize3(refine_res,[h w slices],'nearest');
    threshold_res = imresize3(threshold_res,[h w slices],'nearest');
    eig_res_3d = imresize3(curvature_3D_bdary,[h w slices],'nearest');
    eig_res_2d = imresize3(curvature_2D_bdary,[h w slices],'nearest');
    
    cellPath = fullfile(tmp_path, 'InstanceSeg_res', org_name);
    save(cellPath,"refine_res","threshold_res","-v7.3");

    priCvtPath = fullfile(tmp_path, 'priCvt', org_name);
    save(priCvtPath,"eig_res_3d","eig_res_2d","-v7.3");
    
    clearvars -except org_im refine_res tmp_path org_name q tif_files crop_range;
    % step3.4 save tif results
    if q.visualization
        out_dat = gray2RGB_HD(max(min(org_im/255,1),0));
        out_newId = label2RGB_HD(refine_res);
        out = double(out_dat*0.8 + out_newId*0.5);
        tifPath = fullfile(tmp_path, 'InstanceSeg_tif', org_name);
        tifwrite(out, tifPath);
    end
    toc 
end
if canUseGPU
    reset(gpuDevice());
end