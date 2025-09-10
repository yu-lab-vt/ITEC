function [movieInfo, refine_res, threshold_res, invalid_cell_ids] = ...
    removeShortTracks(movieInfo, refine_res, threshold_res, q)
%% This function is to remove cells with size too small

track_len = cellfun(@length, movieInfo.tracks);

invalid_cell_ids = cat(1, find(isnan(movieInfo.particle2track(:,1))), ...
    movieInfo.tracks{track_len<q.shortestTrack});

[movieInfo, refine_res, threshold_res] = ...
    nullify_region(invalid_cell_ids, movieInfo, refine_res, threshold_res);
