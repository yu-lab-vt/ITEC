function g = set_graphPara(g, timepts_to_process, data_path, tmp_path, q)

% generate the needed parameters for cell/region tracking
crop_range = q.crop_range;
[tif_files,~] = get_sorted_files(data_path,q.tps_to_process);
[~, data_name, ~] = fileparts(tif_files(1).name);
dat = tifread(fullfile(data_path, [data_name '.tif']));
if ~isempty(crop_range)
    dat = dat(crop_range(1,1):crop_range(1,2),crop_range(2,1):crop_range(2,2),crop_range(3,1):crop_range(3,2));
end
[h, w, zslices] = size(dat);
ds_scale = q.scaling;
dat_backup = imresize3(dat, round([h/ds_scale w/ds_scale zslices]));
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
dat_backup = padarray(dat_backup, [floor(x_margin/2) floor(y_margin/2) floor(z_margin/2)], 'replicate','pre');
dat_backup = padarray(dat_backup, [ceil(x_margin/2) ceil(y_margin/2) ceil(z_margin/2)], 'replicate','post');
batch_size = round(size(dat_backup)/2^layer_num);

g.maxIter = q.maxIter;
g.timepts_to_process = timepts_to_process;
g.translation_path = fullfile(tmp_path, 'MotionFlow');
g.driftInfo.grid_size = 2^q.layerNum;    % vector numbers each dim, currently cube only
g.driftInfo.batch_size = batch_size;
if g.applyDrift2allCoordinate
    error('Non-rigid version doesn''t accept the option.');
end

[y_batch, x_batch, z_batch] = meshgrid(0:g.driftInfo.grid_size+1);
if ~isempty(q.stLoc)  % adjust if crop
    y_batch = y_batch*g.driftInfo.batch_size(2) + 0.5 - g.driftInfo.batch_size(2)/2 - st_loc(2)/sc_f;
    x_batch = x_batch*g.driftInfo.batch_size(1) + 0.5 - g.driftInfo.batch_size(1)/2 - st_loc(1)/sc_f;
    z_batch = z_batch*g.driftInfo.batch_size(3) + 0.5 - g.driftInfo.batch_size(3)/2 - st_loc(3);
else
    y_batch = y_batch*g.driftInfo.batch_size(2) + 0.5 - g.driftInfo.batch_size(2)/2;
    x_batch = x_batch*g.driftInfo.batch_size(1) + 0.5 - g.driftInfo.batch_size(1)/2;
    z_batch = z_batch*g.driftInfo.batch_size(3) + 0.5 - g.driftInfo.batch_size(3)/2;
end
g.driftInfo.y_batch = y_batch;
g.driftInfo.x_batch = x_batch;
g.driftInfo.z_batch = z_batch;  % vector locations in original image with one padding
end