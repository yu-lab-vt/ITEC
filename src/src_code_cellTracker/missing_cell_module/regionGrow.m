function [newLabel, n] = regionGrow(newLabel, scoreComp, fMap, connect, cost_design, bg2sink)
% grow the region to its boundary based on graph-cut
% INPUT:
%     newLabel: the label of regions segmented by principal curvature
%     scoreComp: score that used to grow the region, can be principal curvature
%     or the gradient. Here we use gradient
%     fMap: the foreground map to indicate the region can be grown on
%     connect: 6, 26 (TODO: 10(8+2)) connection for connecting edges in the graph
%     cost_design: how to design the cost in the Graph-Cut
%     bg2sink: whether we link background to sink
% OUTPUT:
%     newLabel: new segmentation after region growing

if nargin == 5
    bg2sink = true;
end
n = double(max(newLabel(:)));
%fMap = imdilate(fMap, strel('cube', 5));
L = zeros(size(newLabel));
for j=1:n
    sMap = newLabel==j;
    if isempty(find(sMap,1))
        continue;
    end
    if bg2sink % consider background as sink as well
        tMap = ~fMap;%
    else
        tMap = false(size(fMap));%
    end
    
    other_id_locs = newLabel~=j & newLabel>0;
    tMap(other_id_locs) = 1; % add other regions
    inScoreMap = scoreComp;
    %inScoreMap(other_id_locs) = inf; % add other regions
    [dat_in, src, sink] = graphCut_negHandle_mat(inScoreMap, fMap, sMap, ...
        tMap, connect, cost_design, bg2sink);
    G = digraph(dat_in(:,1),dat_in(:,2),dat_in(:,3));
    if ~isempty(find(isnan(dat_in(:)), 1)) || isnan(sink)
        keyboard;
    end
    [~,~,cs,~] = maxflow(G, src, sink); % cs: fg, ct: bg
    cs = cs(cs<numel(newLabel));
    %cs = cs(fMap(cs));
    cur_l = newLabel(cs);
    if length(unique(cur_l))>2
        keyboard;
    end
    reg_locs = cs;
    L(reg_locs) = j;
end

newLabel = L;