function tif2bdv(tif_folder_path, save_data_name, timepts_to_process, st_loc, sz_crop, crop_range)

%% This function is to convert tif files to mastodon accepted data format
% INPUT:
%     tif_folder_path:tif path
%     save_data_name: name of new h5 file
%     timepts_to_process:
%     st_loc:crop coordinate of data
%     sz_crop:

% scaling setting
if ~isempty(st_loc)
    end_loc = st_loc + sz_crop - 1;
end

% parameter
view_num = 1;
res_mat = [1 1 1; 2 2 2;]';
sub_mat = [16 16 16; 8 8 8]';

% write hdf5 data
h5create([save_data_name '.h5'],'/s00/resolutions',size(res_mat));
h5write([save_data_name '.h5'], '/s00/resolutions', res_mat);
h5create([save_data_name '.h5'],'/s00/subdivisions',size(sub_mat));
h5write([save_data_name '.h5'], '/s00/subdivisions', sub_mat);
l_num = size(res_mat,2);

% read tif file
% tif_files = dir(fullfile(tif_folder_path, '*.tif'));
% time_num = numel(tif_files);
time_num = length(timepts_to_process);
for tt = 1:time_num
    fprintf('Writing time %d\n', tt);
    data = tifread(fullfile(tif_folder_path, timepts_to_process(tt)+'.tif'));
    if ~isempty(crop_range)
        data = data(crop_range(2,1):crop_range(2,2),crop_range(1,1):crop_range(1,2),crop_range(3,1):crop_range(3,2));
    end
    if ~isempty(st_loc)
        data = data(st_loc(1):end_loc(1), ...
               st_loc(2):end_loc(2),st_loc(3):end_loc(3));
    end
    [x,y,z] = size(data);
    % data transform
    data_t = zeros(y,x,z);
    for zz = 1:z
        data_t(:,:,zz) = data(:,:,zz)';
    end
    data = data_t;
    data = single(data);

    % write h5 file
    t_ind = num2str(100000+tt-1);
    t_ind = t_ind(2:end);
    s_ind = '00';
    for ll = 0:l_num-1
        l_ind = num2str(ll);
        data_temp = imresize3(data,round(size(data)./res_mat(:,ll+1)'));
        %h5create([save_data_name '.h5'],['/t' t_ind '/s' s_ind '/' l_ind '/cells'],...
        %    size(data_temp),'Datatype','uint16','ChunkSize',sub_mat(:,ll+1)');
        h5create([save_data_name '.h5'],['/t' t_ind '/s' s_ind '/' l_ind '/cells'],...
            size(data_temp),'Datatype','uint16');
        h5write([save_data_name '.h5'],['/t' t_ind '/s' s_ind '/' l_ind '/cells'],data_temp);
    end
end


% write xml file
docNode = com.mathworks.xml.XMLUtils.createDocument('SpimData');
root = docNode.getDocumentElement;
root.setAttribute('version','0.2');
basePath = docNode.createElement('BasePath');
basePath.setAttribute('type','relative');
basePath.appendChild(docNode.createTextNode('.'));
root.appendChild(basePath);

% sequence description
seqDes = docNode.createElement('SequenceDescription');

imLoader = docNode.createElement('ImageLoader');
imLoader.setAttribute('format','bdv.hdf5');
hdf5 = docNode.createElement('hdf5');
hdf5.setAttribute('type','relative');
hdf5.appendChild(docNode.createTextNode('embryo_data_h5.h5'));
imLoader.appendChild(hdf5);
seqDes.appendChild(imLoader);

viewSets = docNode.createElement('ViewSetups');
for ii = 0:view_num-1
    viewSet = docNode.createElement('ViewSetup');
    id = docNode.createElement('id');
    id.appendChild(docNode.createTextNode(num2str(ii)));   % id name
    view_size = docNode.createElement('size');
    view_size.appendChild(docNode.createTextNode(...
        [num2str(y) ' ' num2str(x) ' ' num2str(z)]));
    voxelSize = docNode.createElement('voxelSize');
    unit = docNode.createElement('unit');
    unit.appendChild(docNode.createTextNode('pixel')); 
    unit_size = docNode.createElement('size');
    unit_size.appendChild(docNode.createTextNode('1 1 1')); 
    voxelSize.appendChild(unit);
    voxelSize.appendChild(unit_size);
    viewSet.appendChild(id);
    viewSet.appendChild(view_size);
    viewSet.appendChild(voxelSize);
    viewSets.appendChild(viewSet);
end
seqDes.appendChild(viewSets);

timePoints = docNode.createElement('Timepoints');
timePoints.setAttribute('type','range');
first = docNode.createElement('first');
first.appendChild(docNode.createTextNode('0'));
timePoints.appendChild(first);
last = docNode.createElement('last');
last.appendChild(docNode.createTextNode(num2str(time_num-1)));
timePoints.appendChild(last);
seqDes.appendChild(timePoints);

root.appendChild(seqDes);

% view registration
viewRegs = docNode.createElement('ViewRegistrations');
for tt = 0:time_num-1
    for ii = 0:view_num-1 
        viewReg = docNode.createElement('ViewRegistration');
        viewReg.setAttribute('timepoint',num2str(tt));
        viewReg.setAttribute('setup',num2str(ii));
        viewTrans = docNode.createElement('ViewTransform');
        viewTrans.setAttribute('type','affine');
        affine = docNode.createElement('affine');
        affine.appendChild(docNode.createTextNode(...
            '1 0 0 0 0 1 0 0 0 0 1 0'));
        viewTrans.appendChild(affine);
        viewReg.appendChild(viewTrans);
        viewRegs.appendChild(viewReg);
    end
end
root.appendChild(viewRegs);
xmlwrite([save_data_name '.xml'],docNode);


