function [movieInfo, refine_res, threshold_res, g] = missing_cell_module(...
    movieInfo, refine_res, threshold_res, ...
    embryo_vid, eigMaps, g, q)
% This module mainly detect missing cells cells by re-check the jump, start
% and stop point of trajectories. 

% 1.1 linking allowing jump but no split/merge
[~, g, dat_in] = trackGraphBuilder_cell(movieInfo, g);
movieInfo = mccTracker(dat_in, movieInfo, g);

% 1.2 remove the tracks that are too short
if q.shortestTrack > 0
    [movieInfo, refine_res, threshold_res, invalid_cell_ids] = ...
        removeShortTracks(movieInfo, refine_res, threshold_res, q);
else
    invalid_cell_ids = [];
end

% 1.3 detect missing cells from jump, start and stopping point
[movieInfo, refine_res, threshold_res, added_cell_id] = add_missing_cell(...
    movieInfo, refine_res, embryo_vid, g, ...
    threshold_res, eigMaps, q);

% 1.4 update movieInfo and refine_res
[movieInfo, refine_res, g] = movieInfo_update(movieInfo, ...
    refine_res, cat(1, added_cell_id, invalid_cell_ids), g);