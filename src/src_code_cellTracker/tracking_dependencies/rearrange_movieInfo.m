function [movieInfo, out_refine] = rearrange_movieInfo(movieInfo, refine_res)

%% This function is to re-arrange the order of the labels in refine_res
% based on the re-label, rearrange the order of movieInfo
% INPUT:
%        movieInfo:all tracking results
%        refine_res:segmentation results
% OUTPUT:
%        movieInfo,refine_res

% NOTE:it will also automatically remove empty regions
out_refine = cell(numel(refine_res), 1);
map = cell(numel(refine_res), 1);
cnt_perframe = zeros(numel(refine_res),1);
for i=1:numel(refine_res)
    [out_refine{i}, cnt_perframe(i), map{i}] = rearrange_id(refine_res{i});
end

for i=2:numel(refine_res)
    increment = sum(cnt_perframe(1:i-1));
    map{i}(:,2) = map{i}(:,2) + increment;
    org_id = map{i}(:,1);
    increment = sum(movieInfo.n_perframe(1:i-1));
    max_num = movieInfo.n_perframe(i);
    org_id(org_id<=max_num) = org_id(org_id<=max_num) + increment;
    map{i}(:,1) = org_id;
end
maps = cat(1, map{:});
new_od = maps(:,1);

movieInfo.Ci = movieInfo.Ci(new_od);
movieInfo.xCoord = movieInfo.xCoord(new_od);
movieInfo.yCoord = movieInfo.yCoord(new_od);
movieInfo.zCoord = movieInfo.zCoord(new_od);
movieInfo.orgCoord = movieInfo.orgCoord(new_od,:);
movieInfo.frames = movieInfo.frames(new_od);

movieInfo.vox = movieInfo.vox(new_od);
movieInfo.voxIdx = movieInfo.voxIdx(new_od);
movieInfo.nei = movieInfo.nei(new_od);
[id_st, od] = sort(maps(:,1),'ascend');
id_map = nan(id_st(end), 1);
for i=1:length(id_st)
    id_map(id_st(i)) = maps(od(i),2);
end
for i=1:numel(movieInfo.nei)
    if sum(isnan(id_map(movieInfo.nei{i})))>0
        disp(i);
        keyboard;
    end
    movieInfo.nei{i} = id_map(movieInfo.nei{i});
end
movieInfo.CDist = movieInfo.CDist(new_od);
movieInfo.CDist_i2j = movieInfo.CDist_i2j(new_od);
movieInfo.CDist_j2i = movieInfo.CDist_j2i(new_od);

movieInfo.Cij = movieInfo.Cij(new_od);
movieInfo.ovSize = movieInfo.ovSize(new_od);
movieInfo.Cji = movieInfo.Cji(new_od);
movieInfo.preNei = movieInfo.preNei(new_od);
for i=1:numel(movieInfo.preNei)
    if sum(isnan(id_map(movieInfo.preNei{i})))>0
        disp(i);
        keyboard;
    end
    movieInfo.preNei{i} = id_map(movieInfo.preNei{i});
end
movieInfo.preOvSize = movieInfo.preOvSize(new_od);
movieInfo.n_perframe = cnt_perframe;
if isfield(movieInfo, 'node_tested_st_end_jump')
    id_map(isnan(id_map)) = 0;% NOTE: id_map changed its nan to 0
    movieInfo.node_tested_st_end_jump = ...
        movieInfo.node_tested_st_end_jump(new_od,:);
    jump_end = movieInfo.node_tested_st_end_jump(:,3);
    movieInfo.node_tested_st_end_jump(jump_end~=0,3) = ...
        id_map(jump_end(jump_end~=0));
    jump_start = movieInfo.node_tested_st_end_jump(:,4);
    movieInfo.node_tested_st_end_jump(jump_start~=0,4) = ...
        id_map(jump_start(jump_start~=0));
end
if isfield(movieInfo, 'arc_avg_mid_std')
    movieInfo.arc_avg_mid_std = ...
        movieInfo.arc_avg_mid_std(new_od,:);
end
end