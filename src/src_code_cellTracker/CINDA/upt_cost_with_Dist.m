function movieInfo = upt_cost_with_Dist(movieInfo)
% if the jump ratio changed, we should update the cost related to jump
% ratio

nei = movieInfo.nei;
phatDist = movieInfo.ovGamma;
for i=1:length(movieInfo.xCoord)
    fr_diff = movieInfo.frames(nei{i}) - movieInfo.frames(i);
    if ~isempty(fr_diff)
        movieInfo.Cij{i} = overlap2cost(movieInfo.CDist{i}, phatDist, ...
            movieInfo.jumpRatio(fr_diff));
    end
end

Cji = cell(numel(nei),1);
for i=1:numel(nei)
    for j=1:length(nei{i})
        Cji{nei{i}(j)} = cat(1, Cji{nei{i}(j)}, movieInfo.Cij{i}(j));
    end
end

movieInfo.Cji = Cji;



end