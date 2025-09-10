function [movieInfo, detections_YXZ, voxIdxList, voxList] = tree2tracks_cell(...
    det_maps, q, detections)
% change the tracking results from saving in a tree structure to isolated
% form, where each track are saved in a single cell
% INPUT:
% det_maps: t-by-1 cells, each cell corresponds to label map in one
% frame. For each cell, if it is n*3, each row is the yxz coordicates of
% one detection. If it is n*4, the last column is the parent id in the
% previous frame, which means tracking results is attained.
% track_flag: do we need to re-format the trajectories? Default is true(yes).
% OUTPUT:
% movieInfo: a struct consist of all the infor needed for our own tracking
% framework such as: y,x,z coordinate, frame stamps. In movieInfo, all the
% detections are in one matrix rather than cells as in the input
% "detections".

if nargin < 3
    detections = [];
end
movieInfo=struct('xCoord',[],'yCoord',[], 'zCoord', [], 'n_perframe', [], ...
    'label', [], 'frames', [], 'vox', [], 'voxIdx',[], ...
    'tracks',[], 'particle2track', []);
% NOTE: vox will be influenced by drifting but voxIdx will not. This is to
% make the location identificatoin easier

% extract all centers first
detections_YXZ = cell(numel(det_maps),1);
labels = cell(numel(det_maps),1);
voxIdxList = cell(numel(det_maps),1);
voxList = cell(numel(det_maps),1);
n_perframe = zeros(numel(det_maps), 1);
for i=1:numel(det_maps)
    s = regionprops3(det_maps{i}, 'Centroid','VoxelList','VoxelIdxList');
    if iscell(s.VoxelIdxList)
        voxIdxList{i} = s.VoxelIdxList;
        voxList{i} = s.VoxelList;
    else
        voxIdxList{i} = cell(1,1);
        voxIdxList{i}{1} = s.VoxelIdxList;
        voxList{i} = cell(1,1);
        voxList{i}{1} = s.VoxelList;
    end
    if ~isempty(voxIdxList{i})
        labels{i} = [1:numel(voxList{i})]';
        detections_YXZ{i} = [s.Centroid(:,2) s.Centroid(:,1) s.Centroid(:,3)];  % Centroid is YXZ direction, so it's XYZ.
        n_perframe(i) = numel(voxIdxList{i});
    end
end
movieInfo.voxIdx = cat(1,voxIdxList{:});
movieInfo.vox = cat(1,voxList{:}); % this is in the order of XYZ
movieInfo.n_perframe = n_perframe;
movieInfo.label = cat(1, labels{:});
% coordinates
for i=1:numel(detections_YXZ)
    detections_YXZ{i} = cat(2, detections_YXZ{i}, i*ones(size(detections_YXZ{i},1),1));
end
det_all = cat(1, detections_YXZ{:});
movieInfo.yCoord = det_all(:,1);                                                % change to YXZ again
movieInfo.xCoord = det_all(:,2);
movieInfo.zCoord = det_all(:,3);
movieInfo.frames = det_all(:,end); % time
%% if we input possible linkings
if ~isempty(detections) && iscell(detections)
    [tracks, particle2track, parents, kids, n_perframe] = detection2tracks(detections);
    movieInfo.tracks = tracks;
    movieInfo.parents = parents;
    movieInfo.kids = kids;
    movieInfo.particle2track = particle2track;
    movieInfo.n_perframe = n_perframe;
end