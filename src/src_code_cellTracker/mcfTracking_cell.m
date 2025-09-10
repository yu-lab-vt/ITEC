function [movieInfo, refine_res,threshold_res] = mcfTracking_cell(det_maps,...
    embryo_vid, threshold_res,eigMaps, g, q)

%% This function is to perform tracking based on error correction
% INPUT:
%     det_maps: cells contains the label maps of all the frames
%     embryo_vid: original data
%     q: paras_tracking
% OUTPUT:
%     movieInfo: tracking results
%     refine_res: detected regions with each region one unique id
%     threshold_res: median intensity of detected regions

g.loopCnt = 0;

%% step1:information initialization

% initial transition cost
[movieInfo, det_YXZ, voxIdxList, voxList] = tree2tracks_cell(det_maps, q, false);% false means we do not use existing tracking results
movieInfo.orgCoord = [movieInfo.xCoord, movieInfo.yCoord, movieInfo.zCoord];
movieInfo.Ci = zeros(g.particleNum,1)+g.observationCost; % use constant as observation cost
movieInfo = transitCostInitial_cell(det_maps, det_YXZ, voxIdxList, voxList,...
    movieInfo,g);

% do a simple linking to estimate the drift of the data
[~, g, dat_in] = trackGraphBuilder_cell(movieInfo, g);
movieInfo4gamma = mccTracker(dat_in, movieInfo, g, false, false);
g.jumpCost = movieInfo4gamma.jumpRatio;              % no need here
movieInfo = transitCostUpt_cell(movieInfo4gamma, g); % drift corrected

refine_res = det_maps;

if q.removeSamllRegion
    % remove tiny cells
    [movieInfo, refine_res, threshold_res, invalid_cell_ids] = ...
        removeTinyCells(movieInfo, refine_res, threshold_res, q);
    % update movieInfo and refine_res
    [movieInfo, refine_res, g] = movieInfo_update(movieInfo, ...
        refine_res, invalid_cell_ids, g);
end

% add an invalid gap map
movieInfo.validGapMaps = cell(numel(refine_res),1);
for i=1:numel(refine_res)
    movieInfo.validGapMaps{i} = true(size(refine_res{i}));
end

%% step2:iterative update transition cost start
loopCnt = 1;
g.loopCnt = loopCnt;
while 1
    fprintf('--------------------Error Correction %d/%d--------------------\n', loopCnt, g.maxIter);
    % module one: split/merge (optional: remove small regions)
    fprintf('----------Segmentation Correction----------\n');
    tic;
    for dummy = 1:3  
        [movieInfo, refine_res, threshold_res, g, ~] = ...
            split_merge_module(movieInfo, refine_res, threshold_res, ...
            embryo_vid, eigMaps, g, q);
    end
    toc
    fprintf('----------Missing Cell Redetection----------\n');
    tic;
       % module two: missing cells (optional: remove short tracks) 
    [movieInfo, refine_res, threshold_res, g] = ...
        missing_cell_module(movieInfo, refine_res, threshold_res, ...
        embryo_vid, eigMaps, g, q);
    toc
    loopCnt = loopCnt + 1;
    g.loopCnt = loopCnt;
    if loopCnt > g.maxIter
        break;
    end
end
fprintf('--------------------Tracklets Association--------------------\n');
% module three: merge over-split cell by tracklets association
[movieInfo, refine_res, g] = broken_tracks_module(movieInfo, refine_res, g, q);
% module four:test if broken tracks can be merged
movieInfo = mergeBrokenTracks(movieInfo, g, q);