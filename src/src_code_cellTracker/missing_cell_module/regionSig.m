function [zscore,z_debias, sz_nei, sigma] = regionSig(regMap, vidComp, fmap, validNeiMap, OrSt)
% GETORDERSTAT Compute order statistics
% d: transformed data. smask: synapse mask.
% bmask: background mask, MUST be connected. imgVar: image variance
bnd_nei_radius = 3;
sph = strel('sphere', bnd_nei_radius);
se = strel(sph.Neighborhood(:,:,bnd_nei_radius+1));
fg_locs = regMap & ~imerode(regMap,se); % h*w*slice                         % out 3 slices of foreground

% find balanced neighbors
% absdif = 0;
% v=0;

bnd_nei_gap = 0;
nei_locs = findValidNeiReg(regMap, validNeiMap, bnd_nei_gap,...
        bnd_nei_radius, true, se);      % h*w*slice
fg_locs = fg_locs & imdilate(nei_locs, se);                             % too far to background are removed

fg = vidComp(fg_locs);
fg_neighbors = vidComp(nei_locs);
sz_nei = length(fg_neighbors);
% approximation of mu and sigma
M = max(length(fg), 10);
N = max(length(fg_neighbors), 10);

if M>10*N
    zscore = nan;
    z_debias = nan;
    sz_nei = nan;
    sigma = nan;
else
    fmap(fg_locs | nei_locs) = false;
    nanVec = vidComp(fmap);
    [zscore,z_debias, sigma] = ordStats(fg, fg_neighbors, nanVec, OrSt);
end

