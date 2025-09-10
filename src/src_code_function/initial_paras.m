function q = initial_paras()

%% This function is to initialize the general parameters 
% OUTPUT:
%      q:general parameters       

q.scale_term = 255;
q.z_resolution = 1;
q.xy_downSampleScale = 1;
q.minSize = 10;         % cell size
q.maxSize = 100000;     % cell size
q.filter_sigma = 0;
q.tps_to_process = [];
q.crop_range = [];
q.shift = [20 20 20];
q.curveThres = -5;
q.data_path = '../data';
q.result_path = '../result';  
q.start_tm = [];
q.end_tm = [];
q.bgIntensity = 0;

end