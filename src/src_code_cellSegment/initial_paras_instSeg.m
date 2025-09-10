function q = initial_paras_instSeg(p)

%% This function is to initialize the parameters for cell segmentation
% INPUT:    
%      p:general parameters
% OUTPUT:
%      q:parameters of segmentation       

q.data_path = p.data_path;
q.tmp_path = p.tmp_path;
q.result_path = p.result_path;
q.curveThres = p.curveThres;
q.scaleTerm = p.scale_term;
q.zRatio = p.z_resolution;
q.downSampleScale = p.xy_downSampleScale;
q.minSize = p.minSize;              % cell size
q.minSeedSize = ceil(q.minSize/10); % seed size
q.maxSize = p.maxSize;              % cell size
q.maxSeedSize = p.maxSize;          % seed size
q.sigma = p.filter_sigma;
q.tps_to_process = p.tps_to_process;
q.crop_range = p.crop_range;
q.im_resolution = [1 1 q.zRatio/q.downSampleScale];
q.shift = p.shift;        
q.bgIntensity = p.bgIntensity;
q.clipping = p.clipping;

q.boundaryDetect = true;
q.visualization = true;      % save deteciton images to ./tmp/InstanceSeg_tif
q.addslice = true;

q.forezThres = 3;            % zscore threshold of foreground detection  
q.diffIntensity = 0;
q.smFactorLst = 2;           % principle curvature smooth factor
q.varEst = 'filter';

% If we scaled the data
scaling = q.downSampleScale;
if scaling ~= 1
    q.minSize = ceil(q.minSize/scaling^2);         % cell size
    q.minSeedSize = ceil(q.minSeedSize/scaling^2); % seed size
    q.maxSize = ceil(q.maxSize/scaling^2);         % cell size
    q.maxSeedSize = ceil(q.maxSeedSize/scaling^2); % seed size    
    q.shift(1:2) = floor(q.shift(1:2)/scaling);
    q.sigma(1:2) = q.sigma(1:2)/scaling;
end

end