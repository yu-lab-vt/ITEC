function q = initial_paras_tracking(p)

%% This function is to initialize the parameters for tracking
% INPUT:    
%      p:general parameters
% OUTPUT:
%      q:parameters of tracking       

q.data_path = p.data_path;
q.tmp_path = p.tmp_path;
q.result_path = p.result_path;
q.motionflow_sigma = 1;                % Gaussian pyramid smoothing sigma  
q.motionflow_padSize = [15 15 5];      % should be longer than max motion distance
q.useSegRes = true;         % use segmentation results to help estimation. Not suggest to set false.
q.useMotionFlow = true;
q.curveThres = p.curveThres;
q.minSize = p.minSize;     % cell size
q.maxSize = p.maxSize;     % cell size
q.minSeedSize = round(p.minSize/10); % seed size
q.maxSeedSize = p.maxSize; % seed size
q.scaling = p.xy_downSampleScale;
q.sigma = p.filter_sigma;
q.scaleTerm = p.scale_term;
q.tps_to_process = p.tps_to_process;
q.crop_range = p.crop_range;
q.im_resolution = [1 1 p.z_resolution/p.xy_downSampleScale]; 
q.layerNum = 3;    % Gaussian pyramid layers. (x&y size/dsScale/2^layerNum) should be integers.
q.maxIter = 5;
q.stLoc = [];
q.szCrop = [];
q.max_dist = 100;
q.max_nei = 5;
q.shift = p.shift;
q.division_thres = 0.95;

% If we scaled the data
scaling = q.scaling;
if scaling ~= 1
    q.minSize = ceil(q.minSize/scaling^2);% cell size
    q.minSeedSize = ceil(q.minSeedSize/scaling^2); % seed size
    q.maxSize = ceil(q.maxSize/scaling^2);% cell size
    q.maxSeedSize = ceil(q.maxSeedSize/scaling^2); % seed size    
    q.shift(1:2) = floor(q.shift(1:2)/scaling);
    q.sigma(1:2) = q.sigma(1:2)/scaling;
end

q.cost_design = [1, 2];
q.growConnectInTest = 4;
q.growConnectInRefine = 6;
q.edgeConnect = 48; % three circle of neighbors
% deal with one component each time
q.neiMap = 26;
q.shrinkFlag = true;
q.fgBoundaryHandle = 'leaveAloneFirst'; % leaveAloneFirst, compete or repeat:
% if the fg is touching the boundary of the intial foreground, we can choose to 
% (1) leaveAloneFirst: if after gap testing, the region is still large, we
% enlarge the foreground and re-do our pipeline
% (2) repeat: enlarge the foreground and re-do pipeline immediately, not 
% waiting for the next gap testing step
% (3) compete: using the boundary as another region to compete with seed 
% region the split the fg. This method is default when do tracking

q.saveAllResults = true;
q.saveSegResult = true;
q.shortestTrack = 0; % the shortest path we want, cells in other tracks will be removed
q.removeSamllRegion = true; % though we have threshold, we did not
q.growSeedinTracking = true;
% there may be results dominated by other bright cells
q.multiSeedProcess = true; % did we add multiple cells simultaneously or one by one
q.splitRegionInTracking = true;

end