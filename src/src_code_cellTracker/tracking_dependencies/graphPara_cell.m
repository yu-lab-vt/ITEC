function g = graphPara_cell(particleNum)

%% This function is to generate the needed parameters for cell/region tracking
% the parameters include some basic information about detected cells

g.cycle_track = true; % true: circulation framework to solve tracking problem
g.k = 3; % maximum number of jump allowed
g.particleNum = particleNum; % cell number
g.realEnter = chi2inv(1-0.01/g.particleNum, 1)/2; % 12.3546 is from chi2inv(1-0.01/particleNum) / 2
g.c_en = g.realEnter;% cost of appearance and disappearance in the scene
g.c_ex = g.c_en;
g.observationCost = -(g.c_en+g.c_ex)+0.00001; % make sure detections are all included
g.jumpCost = [];   %abs(g.observationCost/g.k); % how much we should punish jump frames
g.trackLength4var = 5;% tracks with smaller length will not be used to cal variance 
g.splitMergeHandle = 'noJumpAll';% noJumpAll: all linking has no jump; noJump: no jump for spliting and merge; none: consider jump
%g.maxIter = 5; % maximum iteration number
g.detect_missing_head_tail = true; % add missing cell, do we consider head/tail node
g.applyDrift2allCoordinate = false; % correct drifting and change all y-, x- and z- coordinate
g.blindmergeNewCell = false; % for a new detected region, blindly merge it to existing one if there is touch
g.par_kid_consistency_check = true; % when split a region in regionRefresh.m, check first if its two parents and two kids are consistent
g.reSplitTest = true; % for a new detected cell, if it is adjacent to another cell, re-split these two using their union voxels
g.stableNodeTest =true;
g.useOldArcProps = false;
g.considerBrokenCellOnly = true; % for linking allowing split/merge, does not consider nodes that has another good linkage already
g.addCellMissingPart = false; % if a cell missed part, we want to detect it, otherwise we can remove seeds that highly overlapped with an existing cell
g.splitMergeCost = true;% if cost of a+b->c is 20, then cost of a->c and b->c are set to 10 if true; otherwise both 20
end