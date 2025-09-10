function [newIdMap_refined,thresholdMap] = regionWiseAnalysis4d_Wei10(seedMap,eig3d,eig2d,vid,q)

%% This function is to refine boundary of seed candidate and remove fp
% INPUT:
%     seedMap: seed candidate of instances
%     eig3d: the 3D curvature used for boundary refine
%     eig2d: the 2D curvature used for boundary refine
%     vid: the input 3D data
% OUTPUT:
%     newIdMap_refined: detected regions with each region one unique id
%     thresholdMap: median intensity of detected regions

%% refine boundary
fprintf('Start boundary refine! \n');
[newIdMap_boundary,thresholdMap] = boundaryRefineModule(seedMap,eig3d,eig2d,vid, q);
newIdMap_refined = region_sanity_check(newIdMap_boundary, q.minSize, q.maxSize);
end