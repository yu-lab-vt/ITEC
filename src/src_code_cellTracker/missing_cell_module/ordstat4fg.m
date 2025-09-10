function [fg, threshold] = ordstat4fg(vidComp, seedRegion, other_id_map, fmapComp, minSize)
% given a seed region, find the most significant region include this region
% and view it as the foreground for further segmentation

if nargin <= 5
    minSize = 10;
end

OrSt.fgTestWay = 'KSecApprox';    %'ttest_varKnown';KSecApprox
if strcmp(OrSt.fgTestWay, 'lookupTable')
    muSigma = paraP3D(0.05, 0,0,255,4, 500, 0.1, 10);
    OrSt.NoStbMu = muSigma.mu;
    OrSt.NoStbSig = muSigma.sigma;
end

corrFactor = 1;
suplb = 30*corrFactor;
infub = 5*corrFactor;
step_i = -1*corrFactor;
    
ub = max(suplb, round(mean(vidComp(seedRegion>0)))); % upper bound intensity level
seedSz = length(find(seedRegion>0));
lb = max(min(vidComp(fmapComp>0)), infub);
if isempty(lb) || isempty(ub) || ub+step_i <= lb
    fg = false(size(vidComp));
    threshold = nan;
    return;
end
regCandidates = cell(round(abs((ub-lb)/step_i))+1, 1);
vid_sm = vidComp;
%vid_sm = imgaussfilt3(vidComp, [1 1 0.5]);

% since we dilate 3 times for boundary and neighbors selection
sph = strel('sphere', 2);
se = strel(sph.Neighborhood(:,:,3));   % equal to strel('disk',2)
otherIdTerritory = imdilate(other_id_map,se);
otherIdTerritory(seedRegion > 0) = 0;    % seedregion has higher priority

test_stat = [];
sz_nei = []; 
s = [];
z = nan(numel(regCandidates), 1);

thrs = ub:step_i:lb;
for cnt = 1:length(thrs)    % parfor is even slower, 2 times slower
    thr = thrs(cnt);
    fgIn = vid_sm >= thr & fmapComp;
    %% select the region containing seed region
    fgIn(otherIdTerritory) = 0;   % remove territory of other seeds      
    l = bwlabeln(fgIn, 6);
    seed_ids = l(seedRegion>0);
    seed_ids = unique(seed_ids(seed_ids>0));
    if isempty(seed_ids)
        continue;
    end
    regCandidates{cnt} = ismember(l, seed_ids);
    curValidNeiMap = ~otherIdTerritory & ~fgIn & fmapComp;
    %% test significance
    coverRatio = length(find(regCandidates{cnt} & seedRegion>0))/seedSz;
    if coverRatio<0.2           % less than 20% of seed region is covered
        continue;
    end
    [z(cnt), test_stat(cnt), sz_nei(cnt), s(cnt)]= regionSig(regCandidates{cnt}, vidComp,...
        fmapComp, curValidNeiMap, OrSt);

end
[v_od, od] = nanmax(z, [], 1);

if isnan(v_od)
    fg = false(size(vidComp));
    threshold = nan;
    return;
end
threshold = thrs(od);
fg_reg = regCandidates{od};
fg = refine_with_seedRegion(fg_reg, seedRegion, minSize);
if isempty(find(fg & seedRegion,1))   % the seedregion no longer related to fg
    fg = false(size(vidComp));
    threshold = nan;
    return;
end