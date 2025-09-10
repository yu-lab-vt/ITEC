function [movieInfo, refine_res, g] = movieInfo_update(...
    movieInfo, refine_res, reg4upt, g)

% we update cost, neigbors of nodes include:
% vox, Cij, Nei, OvSize, CDist; Cji, preNei, preOvSize

reg4upt = unique(reg4upt);
old_reg_upted = reg4upt(reg4upt<=numel(movieInfo.preNei));
timepts = numel(refine_res);
reg_num = numel(movieInfo.voxIdx);
append_cells = cell(reg_num-numel(movieInfo.vox), 1);
movieInfo.vox = cat(1, movieInfo.vox, append_cells);
movieInfo.nei = cat(1, movieInfo.nei, append_cells);
movieInfo.CDist = cat(1, movieInfo.CDist, append_cells);
movieInfo.CDist_i2j = cat(1, movieInfo.CDist_i2j, append_cells);

movieInfo.Cij = cat(1, movieInfo.Cij, append_cells);
movieInfo.ovSize = cat(1, movieInfo.ovSize, append_cells);

if ~isfield(movieInfo, 'drift')
    error('Drift not found!');
end
if isfield(movieInfo, 'node_tested_st_end_jump')
    movieInfo.node_tested_st_end_jump = cat(1, ...
        movieInfo.node_tested_st_end_jump, zeros(numel(append_cells),4));
    invalid_head = cat(1, old_reg_upted, ...
        movieInfo.node_tested_st_end_jump(old_reg_upted, 4));
    invalid_head(invalid_head == 0) = [];
    movieInfo.node_tested_st_end_jump(invalid_head, 3:4) = 0;
end
if isfield(movieInfo, 'arc_avg_mid_std')
    movieInfo.arc_avg_mid_std = cat(1, ...
        movieInfo.arc_avg_mid_std, inf(numel(append_cells),4));
    movieInfo.arc_avg_mid_std(old_reg_upted, :) = inf;
end
for i=1:numel(reg4upt)
    cur_reg = reg4upt(i);
    % upate vox based on voxIdx and drift
    cur_frame = movieInfo.frames(cur_reg);
    if isempty(movieInfo.voxIdx{cur_reg})
        movieInfo.vox{cur_reg} = [];
        continue;
    end
    [y, x, z] = ind2sub(size(refine_res{cur_frame}), movieInfo.voxIdx{cur_reg});
    if g.applyDrift2allCoordinate
        movieInfo.vox{cur_reg} = [x, y, z] - movieInfo.drift(cur_frame, :);
    else
        movieInfo.vox{cur_reg} = [x, y, z];
    end
end

for i=1:numel(reg4upt)
    cur_reg = reg4upt(i);
    % upate vox based on voxIdx and drift
    cur_frame = movieInfo.frames(cur_reg);
    if isempty(movieInfo.voxIdx{cur_reg})
        movieInfo.nei{cur_reg} = [];
        movieInfo.CDist{cur_reg} = [];
        movieInfo.CDist_i2j{cur_reg} = [];
        % movieInfo.CDist_j2i{cur_reg} = [];
        movieInfo.Cij{cur_reg} = [];
        movieInfo.ovSize{cur_reg} = [];
        continue;
    end
    % update nei
    cur_voxIdx = movieInfo.voxIdx{cur_reg};
    cur_nei = [];
    for j=cur_frame+1:cur_frame+g.k
        if j>timepts
            break;
        end
        if ~isfield(g, 'translation') || isempty(cur_voxIdx)
            ids = unique(refine_res{j}(cur_voxIdx));
        else
            [cur_vox_y, cur_vox_x, cur_vox_z] = ind2sub(...
                size(refine_res{j}), cur_voxIdx);
            cur_vox_yxz = [cur_vox_y, cur_vox_x, cur_vox_z] + ...
                round(g.translation(j,:)-g.translation(cur_frame,:));
            cur_vox_yxz = verifyInData(cur_vox_yxz, size(refine_res{j}));
            ids = unique(refine_res{j}(sub2ind(size(refine_res{j}),...
                cur_vox_yxz(:, 1), cur_vox_yxz(:, 2), cur_vox_yxz(:, 3))));
        end
        ids = ids(ids>0);
        increment = sum(movieInfo.n_perframe(1:j-1));
        max_num = movieInfo.n_perframe(j);
        ids(ids <= max_num) = ids(ids <= max_num) + increment;
        cur_nei = cat(1, cur_nei, ids);
    end

    movieInfo.nei{cur_reg} = cur_nei;
end
% can parallel
tmp_res = cell(numel(reg4upt),1);
for i=1:numel(reg4upt)
    cur_reg = reg4upt(i);
    cur_nei = movieInfo.nei{cur_reg};
    if isempty(cur_nei)
        continue;
    end
    % update CDist, ovSize and Cij
    tmp_res{i} = nan(length(cur_nei), 5);
    for nn=1:length(cur_nei)
        % overlapping size distance and cost
        [ovSize, CDist, Cij, CDist_dirWise] = nodes_relations(movieInfo, ...
            cur_reg, cur_nei(nn), g);
        tmp_res{i}(nn,1) = ovSize;
        tmp_res{i}(nn,2) = CDist;
        tmp_res{i}(nn,3) = Cij;
        tmp_res{i}(nn,4) = CDist_dirWise(1);
        tmp_res{i}(nn,5) = CDist_dirWise(2);
    end
end

for i=1:numel(reg4upt)
    cur_reg = reg4upt(i);
    cur_nei = movieInfo.nei{cur_reg};
    if isempty(cur_nei)
        movieInfo.ovSize{cur_reg} = [];
        movieInfo.CDist{cur_reg} = [];
        movieInfo.CDist_i2j{cur_reg} = [];
        movieInfo.Cij{cur_reg} = [];
        continue;
    end
    % update CDist, ovSize and Cij
    movieInfo.ovSize{cur_reg} = tmp_res{i}(:,1);
    movieInfo.CDist{cur_reg} = tmp_res{i}(:,2);
    movieInfo.CDist_i2j{cur_reg} = [tmp_res{i}(:,4) tmp_res{i}(:,5)];
    movieInfo.Cij{cur_reg} = tmp_res{i}(:,3);
end

% update preNei's nei
preNei4upt_part1 = unique(cat(1, ...
    movieInfo.preNei{old_reg_upted}));
addedRegions = reg4upt;%(reg4upt>numel(movieInfo.preNei))
preNei4upt_part2 = cell(numel(addedRegions), 1);
for i=1:numel(addedRegions)
    cur_reg = addedRegions(i);
    % upate vox based on voxIdx and drift
    cur_frame = movieInfo.frames(cur_reg);
    if isempty(movieInfo.voxIdx{cur_reg})
        continue;
        %error('Added an empty region!');
    end
    % update nei
    cur_voxIdx = movieInfo.voxIdx{cur_reg};
    cur_preNei = [];
    for j=cur_frame-1:-1:cur_frame-g.k
        if j<1
            break;
        end
        ids = unique(refine_res{j}(cur_voxIdx));
        ids = ids(ids>0);
        increment = sum(movieInfo.n_perframe(1:j-1));
        max_num = movieInfo.n_perframe(j);
        ids = ids(ids <= max_num);
        ids = ids + increment;
        cur_preNei = cat(1, cur_preNei, ids);
    end
    preNei4upt_part2{i} = cur_preNei;
end
preNei4upt_part2 = unique(cat(1, preNei4upt_part2{:}));
preNei4upt = unique(cat(1, preNei4upt_part1, preNei4upt_part2));

org_nei_cells = movieInfo.nei(preNei4upt);
for i=1:numel(preNei4upt)
    cur_reg = preNei4upt(i);
    cur_frame = movieInfo.frames(cur_reg);
    cur_voxIdx = movieInfo.voxIdx{cur_reg};
    cur_nei = [];
    for j=cur_frame+1:cur_frame+g.k
        if j>timepts
            break;
        end
        if ~isfield(g, 'translation') || isempty(cur_voxIdx)
            ids = unique(refine_res{j}(cur_voxIdx));
        else
            [cur_vox_y, cur_vox_x, cur_vox_z] = ind2sub(...
                size(refine_res{j}), cur_voxIdx);
            cur_vox_yxz = [cur_vox_y, cur_vox_x, cur_vox_z] + ...
                round(g.translation(j,:)-g.translation(cur_frame,:));
            cur_vox_yxz = verifyInData(cur_vox_yxz, size(refine_res{j}));
            ids = unique(refine_res{j}(sub2ind(size(refine_res{j}),...
                cur_vox_yxz(:, 1), cur_vox_yxz(:, 2), cur_vox_yxz(:, 3))));
        end
        ids = ids(ids>0);
        increment = sum(movieInfo.n_perframe(1:j-1));
        max_num = movieInfo.n_perframe(j);
        ids(ids <= max_num) = ids(ids <= max_num) + increment;
        cur_nei = cat(1, cur_nei, ids);
    end
    movieInfo.nei{cur_reg} = cur_nei;
end

tmp_res = cell(numel(preNei4upt),1);
for i=1:numel(preNei4upt)
    cur_reg = preNei4upt(i);
    org_nei = org_nei_cells{i};
    cur_nei = movieInfo.nei{cur_reg};
    CDist_v = nan(length(cur_nei), 1);
    CDist_i2j_v = nan(length(cur_nei), 2);
    ovSize_v = nan(length(cur_nei), 1);
    Cij_v = nan(length(cur_nei), 1);
    for j=1:length(cur_nei)
        locInOrgNei = find(org_nei==cur_nei(j),1);
        if ~isempty(locInOrgNei) && isempty(find(reg4upt==cur_nei(j),1))
            CDist_v(j) = movieInfo.CDist{cur_reg}(locInOrgNei);
            CDist_i2j_v(j,:) = movieInfo.CDist_i2j{cur_reg}(locInOrgNei,:);
            ovSize_v(j) = movieInfo.ovSize{cur_reg}(locInOrgNei);
            Cij_v(j) = movieInfo.Cij{cur_reg}(locInOrgNei);
        else
            % overlapping size distance and cost
            [ovSize, CDist, Cij, CDist_dirWise] = nodes_relations(movieInfo, ...
                cur_reg, cur_nei(j), g);
            CDist_v(j) = CDist;
            CDist_i2j_v(j,:) = CDist_dirWise;
            ovSize_v(j) = ovSize;
            Cij_v(j) = Cij;
        end
    end
    
    tmp_res{i} = [ovSize_v CDist_v Cij_v CDist_i2j_v];
end
for i=1:numel(preNei4upt)
    cur_reg = preNei4upt(i);
    % remove the edges with inf cost: no need. keep them infinity
    valid_nei = 1:length(tmp_res{i}(:,3));
    movieInfo.nei{cur_reg} = movieInfo.nei{cur_reg}(valid_nei);
    movieInfo.ovSize{cur_reg} = tmp_res{i}(valid_nei,1);
    movieInfo.CDist{cur_reg} = tmp_res{i}(valid_nei,2);
    movieInfo.CDist_i2j{cur_reg} = tmp_res{i}(valid_nei,4:5);
    movieInfo.Cij{cur_reg} = tmp_res{i}(valid_nei,3);
end

% update Cji, preNei, preOvSize
movieInfo.Cji = cell(reg_num, 1);
movieInfo.CDist_j2i = cell(reg_num, 1);
movieInfo.preNei = cell(reg_num, 1);
movieInfo.preOvSize = cell(reg_num, 1);

for i=1:numel(movieInfo.nei)
    nei = movieInfo.nei{i};
    for j=1:length(nei)
        movieInfo.preNei{nei(j)} = ...
            cat(1, movieInfo.preNei{nei(j)}, i);
        movieInfo.Cji{nei(j)} = ...
            cat(1, movieInfo.Cji{nei(j)}, movieInfo.Cij{i}(j));
        movieInfo.preOvSize{nei(j)} = ...
            cat(1, movieInfo.preOvSize{nei(j)}, movieInfo.ovSize{i}(j));
        
        movieInfo.CDist_j2i{nei(j)} = ...
            cat(1, movieInfo.CDist_j2i{nei(j)}, movieInfo.CDist_i2j{i}(j,2));
    end
end

org_n_num = numel(movieInfo.Ci);
append_reg_num = reg_num - org_n_num;
% update Ci, xCoord-zCoord, orgCoord
movieInfo.Ci = cat(1, movieInfo.Ci, zeros(append_reg_num,1)+g.observationCost);
movieInfo.xCoord = cat(1, movieInfo.xCoord, zeros(append_reg_num,1));
movieInfo.yCoord = cat(1, movieInfo.yCoord, zeros(append_reg_num,1));
movieInfo.zCoord = cat(1, movieInfo.zCoord, zeros(append_reg_num,1));
movieInfo.orgCoord = cat(1, movieInfo.orgCoord, zeros(append_reg_num,3));
for i=1:reg_num
    if ~isempty(movieInfo.vox{i})
        coo_xyz = mean(movieInfo.vox{i},1);
        movieInfo.xCoord(i) = coo_xyz(1);
        movieInfo.yCoord(i) = coo_xyz(2);
        movieInfo.zCoord(i) = coo_xyz(3);
        if g.applyDrift2allCoordinate
            movieInfo.orgCoord(i,:) = coo_xyz + movieInfo.drift(movieInfo.frames(i), :);
        else
            movieInfo.orgCoord(i,:) = coo_xyz;
        end
    end
end
[movieInfo, refine_res] = rearrange_movieInfo(movieInfo, refine_res);
g.particleNum = numel(movieInfo.Ci);
end