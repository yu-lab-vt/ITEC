function [movieInfo, refine_res, threshold_res, rm_cell_id_idx_p_k] = ...
    nullify_region(id, movieInfo, refine_res, threshold_res, family_handle)
% remove a region from the data
% NOTE: movieInfo needs to be update afterwards for an intact information
% updating
if nargin == 4
    family_handle = true;
end
f_all = movieInfo.frames(id);
real_id = zeros(length(id), 3); % id, real_id, threshold
for i=1:length(id)
    if ~isempty(movieInfo.voxIdx{id(i)})
        real_id(i,2) = refine_res{f_all(i)}(movieInfo.voxIdx{id(i)}(1));
        real_id(i,3) = threshold_res{f_all(i)}(movieInfo.voxIdx{id(i)}(1));
    end
    real_id(i,1) = id(i);
end
f = unique(f_all);

if isscalar(f)
    refine_res{f}(cat(1, movieInfo.voxIdx{id})) = 0;
    threshold_res{f}(cat(1, movieInfo.voxIdx{id})) = 0;
else
    for i=1:length(f)
        cur_id = id(f_all == f(i));
        refine_res{f(i)}(cat(1, movieInfo.voxIdx{cur_id})) = 0;
        threshold_res{f(i)}(cat(1, movieInfo.voxIdx{cur_id})) = 0;
    end
end
rm_cell_id_idx_p_k = cell(4,1); % real_id, voxIdx, parents, kids
rm_cell_id_idx_p_k{1} = real_id;
rm_cell_id_idx_p_k{2} = movieInfo.voxIdx(id);
rm_cell_id_idx_p_k{3} = movieInfo.parents(id);% quite possible is empty
rm_cell_id_idx_p_k{4} = movieInfo.kids(id);% quite possible is empty
if family_handle
    for i=1:length(id)
        p = movieInfo.parents{id(i)};
        for j = 1:length(p)
            tmp_kids = movieInfo.kids{p(j)};
            tmp_kids(tmp_kids==id(i)) = [];
            movieInfo.kids{p(j)} = tmp_kids(:);
        end

        kids = movieInfo.kids{id(i)};
        for j = 1:length(kids)
            tmp_ps = movieInfo.parents{kids(j)};
            tmp_ps(tmp_ps==id(i)) = [];
            movieInfo.parents{kids(j)} = tmp_ps(:);
        end
    end
end
movieInfo.voxIdx(id) = {[]};
movieInfo.parents(id) = {[]};
movieInfo.kids(id) = {[]};


