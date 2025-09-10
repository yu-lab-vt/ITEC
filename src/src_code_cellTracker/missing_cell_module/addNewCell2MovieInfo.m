function [movieInfo, cell_id] = addNewCell2MovieInfo(movieInfo, ...
    cell_idx, parent_kid_vec, cell_frame)
% add an new cell to movieInfo; 
new_cell = cell(1,1);
new_cell{1} = cell_idx;
cell_id = numel(movieInfo.voxIdx) + 1;
movieInfo.voxIdx = cat(1, ...
    movieInfo.voxIdx, new_cell);
if ~isnan(parent_kid_vec(1))
    new_cell{1} = parent_kid_vec(1);
    movieInfo.kids{parent_kid_vec(1)} = cell_id;
else
    new_cell{1} = [];
end
movieInfo.parents = cat(1, ...
    movieInfo.parents, new_cell);

if ~isnan(parent_kid_vec(2))
    new_cell{1} = parent_kid_vec(2);
    movieInfo.parents{parent_kid_vec(2)} = cell_id;
else
    new_cell{1} = [];
end
movieInfo.kids = cat(1, ...
    movieInfo.kids, new_cell);

movieInfo.frames = cat(1, ...
    movieInfo.frames, cell_frame);
end