function [flag, adj_ids] = regionAdjacent(movieInfo, refine_res, r1_id, ...
    r2_id, nhood)
% tell if r2_id is spatially adjacent to r2_id
flag = false;

if nargin == 3 % need all adjacent ids
    r2_id = nan;
end

f1 = movieInfo.frames(r1_id);

real_id = r1_id - sum(movieInfo.n_perframe(1:f1-1));
% real_id = refine_res{f1}(movieInfo.voxIdx{r1_id}(2));
if r1_id ~= real_id + sum(movieInfo.n_perframe(1:f1-1))
    error('cell id is wrong!');
end
if nargin <= 4
    idComp = crop3D(refine_res{f1}, movieInfo.voxIdx{r1_id}, [1 1 1]);
    nhood = zeros(3,3,3); % 10 neighbors
    nhood(:,:,2) = 1; 
    nhood(2,2,:) = 1;
else
    idComp = crop3D(refine_res{f1}, movieInfo.voxIdx{r1_id}, ceil(size(nhood)/2));
end
r1_map = idComp == real_id;
valid_ids = idComp(imdilate(r1_map, nhood) & ~r1_map);

adj_ids = unique(valid_ids(valid_ids>0)) + ...
    sum(movieInfo.n_perframe(1:f1-1));

if ~isempty(find(adj_ids==r1_id,1))
    warning('Adjacent region id should not contain the node under test!');
    adj_ids(adj_ids==r1_id) = [];
end
if ~isempty(find(adj_ids==r2_id,1))
    flag = true;
end
end