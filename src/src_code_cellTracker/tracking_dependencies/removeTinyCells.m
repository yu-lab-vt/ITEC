function [movieInfo, refine_res, threshold_res, invalid_cell_ids] = ...
    removeTinyCells(movieInfo, refine_res, threshold_res, q)
%% This function is to remove cells with size too small

cell_sz = cellfun(@length, movieInfo.voxIdx);
invalid_cell_ids = find(cell_sz < q.minSize | cell_sz > q.maxSize);
if isfield(movieInfo, 'lockedDetection')
    invalid_cell_ids(movieInfo.lockedDetection(invalid_cell_ids)) = [];
end
for i=1:length(invalid_cell_ids)
    fr = movieInfo.frames(invalid_cell_ids(i));
    idx = movieInfo.voxIdx{invalid_cell_ids(i)};
    threshold_res{fr}(idx) = 0;
    refine_res{fr}(idx) = 0;
end

movieInfo.voxIdx(invalid_cell_ids) = {[]};
