function cv_xyz = getCurvature_3D(dat,smFactor,sigma)

%% This function is to get 3D principal curvature of 3D data
% INPUT:    
%         dat:input 3D data
%         smFactor:the Gaussian smoothing factor
%         sigma:extra smoothing factor for correction
% OUTPUT:   
%         cv_xyz:xyz3D principal curvature for 3D data
% We have corrected the bias caused by anisotropic filtering

if nargin == 2
    sigma = [0,0,0];
end
smFactor = [sqrt(smFactor(1)^2+sigma(1)^2),sqrt(smFactor(2)^2+sigma(2)^2),sqrt(smFactor(3)^2+sigma(3)^2)];

%% Calculate anisotropy correction coefficient
L = ceil(smFactor*3)*2+9;
hrow = images.internal.createGaussianKernel(smFactor(1), L(1));
hcol = images.internal.createGaussianKernel(smFactor(2), L(2))';
hslc = images.internal.createGaussianKernel(smFactor(3), L(3));
hslc = reshape(hslc, 1, 1, L(3));
GaussFltr = pagemtimes(hrow*hcol,hslc);

gradFltr_X = [0.5;0;-0.5];
gradFltr_Y = gradFltr_X';
gradFltr_Z = [0.5;0;-0.5];
gradFltr_Z = reshape(gradFltr_Z,1,1,[]);

GX = convn(GaussFltr,gradFltr_X);
GY = convn(GaussFltr,gradFltr_Y);
GZ = convn(gradFltr_Z,GaussFltr);

GXX = convn(GX,gradFltr_X);
GYY = convn(GY,gradFltr_Y);
GZZ = convn(gradFltr_Z,GZ);

GXX = GXX(5:end-4,:,:);
GYY = GYY(:,5:end-4,:);
GZZ = GZZ(:,:,5:end-4);

ratio_xx = sqrt(sum(GXX(:).^2));
ratio_yy = sqrt(sum(GYY(:).^2));
ratio_zz = sqrt(sum(GZZ(:).^2));
ratio_xy = sqrt(ratio_xx*ratio_yy);
ratio_xz = sqrt(ratio_xx*ratio_zz);
ratio_yz = sqrt(ratio_yy*ratio_zz);

%% get 3D curvature
if canUseGPU
    dat = gpuArray(dat);
end
[xx_3D, yy_3D, zz_3D, xy_3D, xz_3D, yz_3D, ~] = Hessian3D(dat,smFactor);

xx_3D = xx_3D/ratio_xx;
xy_3D = xy_3D/ratio_xy;
yy_3D = yy_3D/ratio_yy;
zz_3D = zz_3D/ratio_zz;
xz_3D = xz_3D/ratio_xz;
yz_3D = yz_3D/ratio_yz;

if canUseGPU
    xx_3D = gather(xx_3D);
    xy_3D = gather(xy_3D);
    yy_3D = gather(yy_3D);
    zz_3D = gather(zz_3D);
    xz_3D = gather(xz_3D);
    yz_3D = gather(yz_3D);
end

cv_xyz = cal_pc_3D(xx_3D, yy_3D, zz_3D, xy_3D, xz_3D, yz_3D);

end