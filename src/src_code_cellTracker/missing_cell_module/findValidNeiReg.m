function nei_locs = findValidNeiReg(regMap, validNeiMap, gapSz, ...
    maxRadius, radiusBasedFlag, se_max_radius)
% find the neighboring area for testing significance of foreground in
% regMap
% gapSz: the num of cycled neighbors that not used for neighboring detection
% readiusBasedFalg: true means the neighboring area has the same radius as
% foreground region

if nargin == 3
    maxRadius = inf;
    radiusBasedFlag = false;
    se_max_radius = [];
elseif nargin == 4
    radiusBasedFlag = false;
    se_max_radius = [];
end
if gapSz>0
    sph = strel('sphere', gapSz);
    cycleSe = strel(sph.Neighborhood(:,:,gapSz+1));
    regMap = imdilate(regMap, cycleSe);
end
[h,w,z] = size(regMap);
locs = find(regMap);

%fgSz = length(locs);

[~,~,locsZ] = ind2sub([h,w,z], locs);
z_stacks = unique(locsZ);

nei_locs = false(h,w,z);
for ss=1:length(z_stacks)
    i = z_stacks(ss);
    fgMap = regMap(:,:,i);
    curValidMap = validNeiMap(:,:,i);
    szCurStack = length(find(locsZ==i));
    radius = min(round(sqrt(szCurStack/pi)), maxRadius);
    if radiusBasedFlag
        if radius == maxRadius
            se = se_max_radius;
        else
            sph = strel('sphere', radius);
            se = strel(sph.Neighborhood(:,:,radius+1));
        end
        tmpNei = imdilate(fgMap, se) & curValidMap;
        tmp_locs = (i-1)*h*w + find(tmpNei-fgMap>0);
    else
        for j=1 : radius
            sph = strel('sphere', j);
            se = strel(sph.Neighborhood(:,:,j+1));
            tmpNei = imdilate(fgMap, se) & curValidMap;
            tmpLocs = find(tmpNei-fgMap>0);
            if length(tmpLocs)>=szCurStack || j==radius
                tmp_locs = (i-1)*h*w + tmpLocs;
                break;
            end
        end
    end
    nei_locs(tmp_locs) = true;
end

end