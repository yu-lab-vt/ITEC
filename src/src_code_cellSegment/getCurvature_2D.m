function cv_xy = getCurvature_2D(dat,smFactor)

%% This function is to get 2D principal curvature of 3D data
% INPUT:    
%       dat:input 3D data
%       smFactor:the Gaussian smoothing factor
% OUTPUT:   
%       cv_xy:xy2D principal curvature for 3D data

%% get 2D curvature layer by layer
cv_xy = zeros(size(dat));
slices = size(dat,3);
if canUseGPU
    dat = gpuArray(dat);
end
for i = 1:slices
    dat_tem = dat(:,:,i);
    [xx_2D, yy_2D, xy_2D, ~] = Hessian2D(dat_tem,smFactor);
    cv_xy(:,:,i) = cal_pc_2D(xx_2D, yy_2D, xy_2D);
end

end