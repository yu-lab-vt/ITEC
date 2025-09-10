function comMaps = fgDetectSynQuant(comMapsIn, q)
% Detect the foreground within a cropped region
% INPUT: comMaps which contains all infor about the cropped region

%% step1: use synQuant to refine the region
% get the vidIn/seedregion/otherid
vidIn = comMapsIn.vidComp;
seedRegion = single(comMapsIn.regComp);
other_id_map = comMapsIn.idComp>0 & ~comMapsIn.regComp;
% get valid foreground
[x,y,z] = ndgrid(-5:5,-5:5,-1:1);
se = (x.^2/25 + y.^2/25 + z.^2/1) <= 1;
fMap = imdilate(seedRegion, se);
fMap(other_id_map > 0) = false;
fMap = logical(fMap);

[fg, pickedThreshold] = ordstat4fg(vidIn, seedRegion, other_id_map, fMap, q.minSize);
comMaps = comMapsIn;
comMaps.pickedThreshold = pickedThreshold;
if isnan(pickedThreshold) || isempty(find(fg, 1))   % no valid threshold/region can be found
    comMaps.fmapComp = fg;
    return;
end

%% after getting fg, update score maps
min_pv = min(comMaps.score3dMap(fg));
max_pv = max(comMaps.score3dMap(fg));
comMaps.score3dMap = scale_image(comMaps.score3dMap, 1e-3,1, min_pv, max_pv);

%% other seed regions
% all other seed regions are assigned to the same id
seedRegion(~fg) = 0; 
% it is possible the seed region is not fully covered the boundary of foreground
% should not be included in current region, it is too large. We can either: 
% (1) exclude it by labeling it as other id
% (2) re-define the foreground again
[h, w, zslice] = size(fMap);
fgboundary = false(h, w, zslice);
for i = 1:zslice % does not consider the real boundary
    B = bwboundaries(fMap(:,:,i));
    bnd = cat(1, B{:});
    if isempty(bnd)
        continue;
    end
    idx = sub2ind([h,w], bnd(:,1), bnd(:,2)) + (i-1)*h*w;
    fgboundary(idx) = true;
end
fgboundary(seedRegion>0) = false;
comMaps.fMapBndIdx = find(fgboundary);

if isempty(find(fg(comMaps.fMapBndIdx),1))                          % if the foreground is in fmap
    other_id = other_id_map>0 & fg;                                         
else                                                                        % fg too large and touch the boundary
    if strcmp(q.fgBoundaryHandle, 'leaveAloneFirst')% way 3
        other_id = other_id_map>0 & fg;
    elseif strcmp(q.fgBoundaryHandle, 'compete') || nargout == 1 % way 1
        other_id = (other_id_map>0 | fgboundary) & fg;
    end
end
append_id = nan;
if ~isempty(find(other_id, 1))
    append_id = max(seedRegion(:)) + 1;
    seedRegion(other_id) = append_id;
end

%% test if there is an early stop
comMaps = splitFGintoCells(fg, fgboundary, seedRegion, comMaps, append_id, q);

end