function [q,g] = varEst(imregion, q, g)

%% This function is to estimate the std of 3D pure background noise 
% and the correction factor of curvature
% INPUT:    
%      imregion:input 3D data
%      q:parameters of segmentation        
% OUTPUT:   
%      g:the estimation information of pure background noise
%      q:parameters of segmentation 

%% step1 estimate the std of pure background noise
% we estimate variance through neighborhood information
% calculate the correction coefficient for this variance calculation method
map = randn(size(imregion,1:2));
%map = randn(size(imregion,1:2));
if(~all(q.sigma == 0))
    q.sigma = q.sigma + 10^-8;
    map = imgaussfilt3(map,q.sigma);
end
filter_kernel = ones(5, 5);
filter_kernel(3,3) = 0;
filter_kernel = filter_kernel / 24;
avg_map = imfilter(map, filter_kernel, 'replicate', 'conv');
stdmap = map - avg_map;
varmap = stdmap.^ 2;
med = prctile(varmap(:),50);
correction_factor = std(map(:))/sqrt(med);
% calculate variance layer by layer
if strcmp(q.varEst, 'filter')
    filter_kernel = ones(5, 5);
    filter_kernel(3,3,1) = 0;
    filter_kernel = filter_kernel / 24;
    
    avg_map = imfilter(imregion, filter_kernel, 'replicate', 'conv');
    stdmap = imregion - avg_map;
    varmap = stdmap.^ 2;
    
    varmap_reshaped = permute(varmap, [3, 1, 2]);
    varmap_reshaped = reshape(varmap_reshaped, size(varmap,3), []);
    
    std_z = zeros(size(varmap,3), 1);
    for i = 1:size(varmap,3)
        layer_data = varmap_reshaped(i, :);
        layer_data = layer_data(layer_data ~= 0);
        if ~isempty(layer_data)
            std_z(i) = correction_factor * sqrt(prctile(layer_data,50));
        else
            std_z(i) = 0;
        end
    end
    svar = prctile(std_z(:),50);
% directly calculate variance (not recommended)
elseif strcmp(q.varEst, 'bgdirect')
    svar = std(imregion(:));
else
    error('Invalid variance estimation option: %s', q.varEst);
end
g.svar = svar;

%% step2 estimate the correction factor of curvature calculation
% We use simulation to calculate the correction coefficients for normalizing 
% the filtered noise of different scales to a standard normal distribution
if ~isfield(g,'xyz_ratio_org')
    smFactorLst = 1.5.^(0:3)*q.smFactorLst;
    sm_length = length(smFactorLst);
    xy_ratio = zeros(1,sm_length);
    xyz_ratio = zeros(1,sm_length);
    xy_mean = zeros(1,sm_length); 
    xyz_mean = zeros(1,sm_length); 

    map = randn(size(imregion));
    if(~all(q.sigma == 0))
        q.sigma = q.sigma + 10^-8;
        map = imgaussfilt3(map,q.sigma);
    end
    map = map/std(map(:));
    for i = 1:sm_length
        smFactor = (1./q.im_resolution).*smFactorLst(i);
        cv_xyz_filter = getCurvature_3D(map,smFactor,q.sigma);
        cv_xy_filter = getCurvature_2D(map,smFactor);
        xy_ratio(i) = std(cv_xy_filter(:));
        xyz_ratio(i) = std(cv_xyz_filter(:));
        xy_mean(i) = mean(cv_xy_filter(:));
        xyz_mean(i) = mean(cv_xyz_filter(:));
    end
    g.xy_ratio_org = xy_ratio;
    g.xyz_ratio_org = xyz_ratio;
    g.xy_mean_org = xy_mean;
    g.xyz_mean_org = xyz_mean;
    q.foreThres = (prctile(cv_xyz_filter(:),normcdf(q.forezThres)*100)-xyz_mean(sm_length))...
        /xyz_ratio(sm_length);
end
g.xy_ratio = g.xy_ratio_org * svar;
g.xyz_ratio = g.xyz_ratio_org *svar;
g.xy_mean = g.xy_mean_org *svar;
g.xyz_mean = g.xyz_mean_org *svar;

end