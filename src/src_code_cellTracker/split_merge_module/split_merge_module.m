function [movieInfo, refine_res, threshold_res, g, movieInfo_noJump] = ...
    split_merge_module(movieInfo, refine_res, threshold_res, ...
    embryo_vid, eigMaps, g, q)
%% This module mainly detect overmerge and oversplit cells with a new graph 
% design
if nargout == 5 % save intermediate results
    % 2.1 linking allowing split/merge, but no jump
    movieInfo_noJump = handleMergeSplitRegions(movieInfo, g);

    % 2.2 merge/split regions (NOTE: we will also remove gaps if merge is decided)
    [refine_res, movieInfo, reg4upt, mg_sp_num] = regionRefresh(...
        movieInfo_noJump, refine_res, embryo_vid, g, eigMaps, q);

else % save memory
    % 2.1 linking allowing split/merge, but no jump
    movieInfo = handleMergeSplitRegions(movieInfo, g);
    % 2.2 merge/split regions (NOTE: we will also remove gaps if merge is decided)
    [refine_res, movieInfo, reg4upt, mg_sp_num] = regionRefresh(...
        movieInfo, refine_res, embryo_vid, g, eigMaps, q);
end

% 2.3 remove the regions with extremly small size
if q.removeSamllRegion
    [movieInfo, refine_res, threshold_res, invalid_cell_ids] = ...
        removeTinyCells(movieInfo, refine_res, threshold_res, q);
else
    invalid_cell_ids = [];
end

% 2.4 update movieInfo and refine_res
[movieInfo, refine_res, g] = movieInfo_update(movieInfo, ...
    refine_res, cat(1, reg4upt, invalid_cell_ids), g);
fprintf('We merged %d regions and split %d regions!\n', ...
    mg_sp_num(1), mg_sp_num(2));