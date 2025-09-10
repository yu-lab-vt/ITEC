function [curvature_3D_max,curvature_3D_min,curvature_3D_bdary,curvature_2D_bdary,...
    curvature_2D_min,FGmap] = PrcplCrvtr_scaleInvariant_3D(dat, q, g)

%% This function is to calculate scale-invariant principal curvature for 3D data
% INPUT:    
%      dat:input 3D data
%      q:parameters of segmentation       
%      g:the estimation information of pure background noise
% OUTPUT:   
%      curvature_3D_min: minimum principal curvature of xyz
%      curvature_3D_max: maximum principal curvature of xyz
%      curvature_3D_bdary: median principal curvature of xyz
%      curvature_2D_bdary: median principal curvature of xy
%      curvature_2D_min: minimum principal curvature of xy
%      FGmap: foreground detected by curvature

%% step1 initialize
fprintf('Start curvature calculation! \n');
smFactorLst = 1.5.^(0:3)*q.smFactorLst;
im_resolution = q.im_resolution;
zThres = 4;
dat = single(dat);
N_smNum = length(smFactorLst);
curvature_2D_all = zeros([size(dat) N_smNum],class(dat));
curvature_3D_all = zeros([size(dat) N_smNum],class(dat));

%% step2 iteratively get optimal curvature
% we make the noise follow a standard normal distribution based on simulation
for smCnt = 1:N_smNum
    smFactor = (1./im_resolution).*smFactorLst(smCnt);
    curvature_2D_temp = getCurvature_2D(dat,smFactor);
    curvature_3D_temp = getCurvature_3D(dat,smFactor,q.sigma);
    curvature_2D_all(:,:,:,smCnt) = (curvature_2D_temp-g.xy_mean(smCnt))/g.xy_ratio(smCnt);
    curvature_3D_all(:,:,:,smCnt) = (curvature_3D_temp-g.xyz_mean(smCnt))/g.xyz_ratio(smCnt);
end
curvature_3D_all_tem = curvature_3D_all;

%% step3 remove result smaller than min valid smooth factor
%{
curvature_3D_merged = min(curvature_3D_all,[],4);
BGmap = curvature_3D_merged>-abs(zThres);
FGmap = ~BGmap;
for smCnt = 1:N_smNum
    temp = curvature_3D_all(:,:,:,smCnt);
    if median(temp(FGmap))>-2
        % result smaller than min valid smooth factor
        curvature_3D_all_tem(:,:,:,smCnt) = nan;
    else
        break;          % min smooth factor found
    end
end
%}
%% step4 remove result larger than max valid smooth factor
[curvature_3D_merged,Imin] = min(curvature_3D_all_tem,[],4);
BGmap = curvature_3D_merged>-abs(zThres);
Imin(BGmap) = N_smNum;
FGmap = ~BGmap;
invalidRegion = false(size(curvature_3D_all_tem));
for smCnt = 1:N_smNum
    invalidRegion(:,:,:,smCnt) = Imin<smCnt;
end
curvature_3D_all_tem(invalidRegion) = nan;

%% step5 get the final curvature
bdary_num = max(floor(N_smNum/2),1);
curvature_3D_min = min(curvature_3D_all_tem,[],4);
curvature_3D_max = max(curvature_3D_all_tem,[],4);
curvature_3D_bdary = curvature_3D_all(:,:,:,bdary_num);
curvature_2D_bdary = curvature_2D_all(:,:,:,bdary_num);
curvature_2D_min = min(curvature_2D_all,[],4);
end