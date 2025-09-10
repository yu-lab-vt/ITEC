function [dat_in, src_node, sink_node] = graphCut_negHandle_mat(vid, fMap,...
    sMap, tMap, connect, cost_design, bg2sink)

%% This function is to build a graph for graph cut
% INPUT:
%     vid: 3D (TODO: 2D) matrix indicating the similarity of voxels, it can be
%     principal curvature or the gradient. if it is principal curvature,
%     there may be negative values.
%     fMap: the valid foreground map for segmenting
%     sMap,tMap: the voxel that definitely belongs to src or sink
%     connect: connection for edges in the graph(4,6,8,10,18,26)
%     cost_design: 1 means average; 2 means sqrt;
% OUTPUT:
%     dat_in: the graph with n+1 indicating src and n+2 indicating sink; for a voxel at
%     location ind, its node index should be ind+1
%     src_node:the source id
%     sink_node:the sink id


if nargin == 6
    % if we did not link background to sink, no need to consider such
    % nodes, otherwise bg2sink is true
    bg2sink = true;
end
vox_num = numel(vid);
valid_vox = find(fMap);

nei_mat = neighbours_mat(valid_vox, vid, connect);                         
vox_mat = repmat(valid_vox, 1, connect);                
map = [vox_mat(:) nei_mat(:)];                                           
map = map(~isnan(map(:,2)),:);                                           

if ~bg2sink
    map = map(fMap(map(:,2)),:);
end
p1 = vid(map(:,1));
p2 = vid(map(:,2));
if cost_design(1)==1
    costs = (2./(p1+p2)).^cost_design(2);
elseif cost_design(1)==2
    p2(p2==0) = p1;
    costs = (1./sqrt(p1.*p2)).^cost_design(2);
end

% map of neighbors
adjMap = false(size(vid));  
adjMap(map(:,2)) = 1;

% bidirectional edge
dat_in = cat(1, [map, costs], [map(:,2) map(:,1), costs]); 

% connections to src or sink
src_node = vox_num+1;
srcIds = find(sMap);

% connect source to sMap
dat_in = cat(1, dat_in, [src_node + srcIds*0, srcIds, inf + srcIds*0]);  

% connect sink to tMap    
sink_node = vox_num+2;
sinkIds = find(adjMap & tMap);
if isempty(sinkIds)
    sink_node = nan;
end
dat_in = cat(1, dat_in, [sinkIds, sink_node + sinkIds*0, inf + sinkIds*0]);

% connect boundary to tMap 
boundaryMap = false(size(tMap));
boundaryMap(1,:,:) = true;
boundaryMap(:,1,:) = true;
boundaryMap(:,:,1) = true;
boundaryMap(end,:,:) = true;
boundaryMap(:,end,:) = true;
boundaryMap(:,:,end) = true;
bdIds = find(boundaryMap);
dat_in = cat(1, dat_in, [bdIds, sink_node + bdIds*0, (2./vid(boundaryMap)).^cost_design(2)]); 
end