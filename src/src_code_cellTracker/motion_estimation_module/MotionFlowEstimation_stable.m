function MotionFlowEstimation_stable(data_folder, tmp_path, q)

%% This function is the main function for motion flow estimation
% INPUT:
%      data_folder:path of data
%      tmp_path:path of segmentation result
%      q:parameters of motion flow estimation
% OUTPUT:
%      the output will be stored in tmp_path

%% step1 generate path
fprintf('--------------------Motion Flow Estimation--------------------\n');
fore_folder = fullfile(tmp_path, 'InstanceSeg_res');
save_folder = fullfile(tmp_path, 'MotionFlow');
if ~isfolder(save_folder)
    mkdir(save_folder);
end
tps_to_process = q.tps_to_process;
crop_range = q.crop_range;
[tif_files,~] = get_sorted_files(data_folder,tps_to_process);


%% step2 motion flow estimation
for reg_ind=1:numel(tif_files)-1
    % load data
    fprintf('Estimate motion flow between file %d and %d\n', reg_ind, reg_ind+1);
    tic;
    [~, data1_name, ~] = fileparts(tif_files(reg_ind).name);
    [~, data2_name, ~] = fileparts(tif_files(reg_ind+1).name);
    data1 = tifread(fullfile(data_folder, [data1_name '.tif']));
    data2 = tifread(fullfile(data_folder, [data2_name '.tif']));
    if ~isempty(crop_range)
        data1 = data1(crop_range(2,1):crop_range(2,2),crop_range(1,1):crop_range(1,2),...
            crop_range(3,1):crop_range(3,2));
        data2 = data2(crop_range(2,1):crop_range(2,2),crop_range(1,1):crop_range(1,2),...
            crop_range(3,1):crop_range(3,2));
    end
    data1 = 255*data1/q.scaleTerm;
    data2 = 255*data2/q.scaleTerm;
    if q.useSegRes
        fore2 = load(fullfile(fore_folder, [data2_name '.mat']));
        fore2 = fore2.refine_res>0;
    else
        fore2 = true(size(data2));
    end

    % data prepration
    [h, w, zslices] = size(data1);
    ds_scale = q.scaling;
    data1_backup = imresize3(data1,round([h/ds_scale w/ds_scale zslices]));
    data2_backup = imresize3(data2,round([h/ds_scale w/ds_scale zslices]));
    fore2_backup = imresize3(fore2,round([h/ds_scale w/ds_scale zslices]));

    layer_num = q.layerNum;  
    if mod(h/ds_scale, 2^layer_num) ~= 0
        x_margin = 2^layer_num-mod(h/ds_scale, 2^layer_num);
    else
        x_margin = 0;
    end
    if mod(w/ds_scale, 2^layer_num) ~= 0
        y_margin = 2^layer_num-mod(w/ds_scale, 2^layer_num);
    else
        y_margin = 0;
    end
    if mod(zslices, 2^layer_num) ~= 0
        z_margin = 2^layer_num-mod(zslices, 2^layer_num);
    else
        z_margin = 0;
    end
    data1_backup = padarray(data1_backup, [floor(x_margin/2) floor(y_margin/2) floor(z_margin/2)], 'replicate','pre');
    data1_backup = padarray(data1_backup, [ceil(x_margin/2) ceil(y_margin/2) ceil(z_margin/2)], 'replicate','post');
    data2_backup = padarray(data2_backup, [floor(x_margin/2) floor(y_margin/2) floor(z_margin/2)], 'replicate','pre');
    data2_backup = padarray(data2_backup, [ceil(x_margin/2) ceil(y_margin/2) ceil(z_margin/2)], 'replicate','post');
    if q.useSegRes
        fore2_backup = padarray(fore2_backup, [floor(x_margin/2) floor(y_margin/2) floor(z_margin/2)], 0, 'pre');
        fore2_backup = padarray(fore2_backup, [ceil(x_margin/2) ceil(y_margin/2) ceil(z_margin/2)], 0, 'post');
    else
        fore2_backup = padarray(fore2_backup, [floor(x_margin/2) floor(y_margin/2) floor(z_margin/2)], 1, 'pre');
        fore2_backup = padarray(fore2_backup, [ceil(x_margin/2) ceil(y_margin/2) ceil(z_margin/2)], 1, 'post');
    end
    % motion flow estimation
    remove_list = [];
    for correction_cnt = 1:20
        [finish_flag, remove_list] = registration_main(data1_backup,...
                    data2_backup, fore2_backup, reg_ind, data1_name, save_folder, remove_list, q);
        if finish_flag
            break
        end
        fprintf("Iteration %d:\n", correction_cnt);
        disp(remove_list);
    end
    if ~finish_flag 
        error('Error correction not finished in 20 iterations!');
    end
    toc
end
if canUseGPU
   reset(gpuDevice());
end

end


