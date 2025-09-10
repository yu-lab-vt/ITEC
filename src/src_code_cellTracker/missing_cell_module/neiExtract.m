function neis = neiExtract(movieInfo, region, frame)
% get the neighbors of a cell in a given frame
neis = [];
f = movieInfo.frames(region);
if region > min(numel(movieInfo.preNei), numel(movieInfo.nei))
    return;
end
if frame==f
    return
elseif frame<f
    can_neis = movieInfo.preNei{region};
else
    can_neis = movieInfo.nei{region};
end
if isempty(can_neis)
    return;
end
fs = movieInfo.frames(can_neis);

neis = can_neis(fs==frame);