function movieInfo = transitCostInitial_cell(det_maps, dets_YXZ, ...
    voxIdxList, voxList, movieInfo, g)

%we can learn initial variance and mean of distances between observed object
%locations and estimated locations from data
% INPUT:
%     det_maps: cells containing label maps of all frames
%     dets_YXZ: cells containing center locations of regions for each frame
%     voxIdxList: cells containing voxel indexes of regions for each frame
%     frames: the time/frame infor of all detections
%     g: parameters needed
% OUTPUT:
%     neibIdx: neighbors that linked to each detection
%     Cij: the overlapping ratio based distances
%     edgeJumpCoeff: ratio of jumps among all the linkings

%% using all the data to initialize transition cost
fprintf('Start build intial distance and neighbor cells!\n');
neibIdx = cell(g.particleNum, 1);
CDist = cell(g.particleNum, 1);
CDist_dirwise = cell(g.particleNum, 1);

%% get non_rigid registration info
if isfield(g, 'translation_path')  && isfield(g, 'timepts_to_process')
    timepts_to_process = g.timepts_to_process(1:end-1);
    grid_size = g.driftInfo.grid_size;
    movieInfo.drift.x_grid = cell(length(timepts_to_process),1);
    movieInfo.drift.y_grid = cell(length(timepts_to_process),1);
    movieInfo.drift.z_grid = cell(length(timepts_to_process),1);
    for ii = 1:length(timepts_to_process)
        if exist(fullfile(g.translation_path, timepts_to_process(ii)+'.mat'),'file')
            load(fullfile(g.translation_path, timepts_to_process(ii)+'.mat'), 'phi_current_vec');
            x_grid = padarray(reshape(phi_current_vec(1:3:end-2), [grid_size grid_size grid_size]), [1 1 1], 'replicate'); 
            y_grid = padarray(reshape(phi_current_vec(2:3:end-1), [grid_size grid_size grid_size]), [1 1 1], 'replicate'); 
            z_grid = padarray(reshape(phi_current_vec(3:3:end), [grid_size grid_size grid_size]), [1 1 1], 'replicate'); 
            movieInfo.drift.x_grid{ii} = x_grid;
            movieInfo.drift.y_grid{ii} = y_grid;
            movieInfo.drift.z_grid{ii} = z_grid;
        else
            grid_all = zeros(grid_size+2,grid_size+2,grid_size+2);
            movieInfo.drift.x_grid{ii} = grid_all;
            movieInfo.drift.y_grid{ii} = grid_all;
            movieInfo.drift.z_grid{ii} = grid_all;
        end
    end
end
movieInfo.driftInfo = g.driftInfo;  % for conveinent input

%%
timepts = numel(dets_YXZ);
curLen = 0;
for i=1:timepts
    for j=i+1:i+g.k
        if j>timepts
            break;
        end        
        % deform later frame to previous time point to find correct neighbors
        deform_map = det_maps{i};
        deform_map_size = size(det_maps{i});
        deform_map_size = deform_map_size([2 1 3]);
        deform_map(deform_map~=0) = 0;
        deform_voxIdxList = cell(size(voxIdxList{j}));
        for kk = 1:length(voxIdxList{j})
            frame_shift = getNonRigidDrift([0 0 0], voxList{j}{kk}, i, j, movieInfo.drift, g.driftInfo);
            deform_voxList = voxList{j}{kk} - round(frame_shift);
            deform_voxList = min(deform_voxList, deform_map_size);
            deform_voxList = max(deform_voxList, 1);
            deform_voxList = unique(deform_voxList, 'rows');
            deform_voxIdxList{kk} = sub2ind(size(det_maps{i}), deform_voxList(:,2), deform_voxList(:,1), deform_voxList(:,3));
            deform_map(deform_voxIdxList{kk}) = kk;
        end

        if isfield(g, 'translation')   % not used
            [neighbors, distances, distances_dirWise] = ovDistanceMap(...
                det_maps{i}, det_maps{j}, voxIdxList{i}, voxIdxList{j},...
                g.translation(j,:)-g.translation(i,:));
        else
            [neighbors, distances, distances_dirWise] = ovDistanceMap(...
                det_maps{i}, deform_map, voxIdxList{i}, deform_voxIdxList);
        end
        bsIdxLen = sum(movieInfo.n_perframe(1:j-1));
        for nn = 1:numel(neighbors)
            tmpIdx = neighbors{nn};
            if ~isempty(tmpIdx)
                neibIdx{curLen+nn} = cat(1,neibIdx{curLen+nn}, bsIdxLen+tmpIdx);
                CDist{curLen+nn} = cat(1,CDist{curLen+nn}, distances{nn});
                CDist_dirwise{curLen+nn} = cat(1,CDist_dirwise{curLen+nn}, ...
                    distances_dirWise{nn});
            end
        end
    end
    curLen = curLen+numel(voxIdxList{i});
end
validPts = ~cellfun(@isempty,CDist);
nearestDist = cellfun(@min,CDist(validPts));
% fit the gamma distribution using current overlapping distances
phat = fitTruncGamma(nearestDist);
movieInfo.ovGamma = phat;
Cij = cell(g.particleNum, 1);
CDist_i2j = CDist_dirwise; % !!! CDist_i2j: save both in two columns
for i=1:numel(CDist)
    if isempty(CDist{i})
        continue;
    end
    % overlapping_cost
    Cij{i} = overlap2cost(CDist{i}, phat);
end

% cal the overlapping ratio forward and backward
ovSize = cell(numel(neibIdx),1);
for i=1:numel(neibIdx)
    ovSize{i} = zeros(length(neibIdx{i}),1);
    cur_voxIdxes = movieInfo.voxIdx{i};
    for j=1:length(ovSize{i})
        ovSize{i}(j) = length(intersect(cur_voxIdxes, ...
            movieInfo.voxIdx{neibIdx{i}(j)}));
    end
end
preNei = cell(numel(neibIdx),1);
preOvSize = cell(numel(neibIdx),1);
Cji = cell(numel(neibIdx),1);
CDist_j2i = cell(numel(neibIdx), 1);
for i=1:numel(neibIdx)
    for j=1:length(neibIdx{i})
        preNei{neibIdx{i}(j)} = cat(1, preNei{neibIdx{i}(j)}, i);
        preOvSize{neibIdx{i}(j)} = cat(1, preOvSize{neibIdx{i}(j)}, ovSize{i}(j));
        Cji{neibIdx{i}(j)} = cat(1, Cji{neibIdx{i}(j)}, Cij{i}(j));
        
        CDist_j2i{neibIdx{i}(j)} = cat(1, CDist_j2i{neibIdx{i}(j)}, ...
            CDist_i2j{i}(j,2));
    end
end

movieInfo.CDist = CDist;
movieInfo.CDist_i2j = CDist_i2j;% !!! CDist_i2j: save both i2j and j2i in two columns
movieInfo.CDist_j2i = CDist_j2i;

movieInfo.nei = neibIdx;
movieInfo.preNei = preNei;
movieInfo.ovSize = ovSize;
movieInfo.preOvSize = preOvSize;
movieInfo.Cij = Cij;
movieInfo.Cji = Cji;

fprintf('finish trajectory intialization with purely distance!\n');

end