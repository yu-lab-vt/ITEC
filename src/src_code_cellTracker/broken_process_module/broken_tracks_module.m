function [movieInfo, refine_res, g] = broken_tracks_module(...
    movieInfo, refine_res, g, q)

%% This function is to merge broken tracks due to over-split

%% module 3.1 find nearest cell pairs and merge them
[movieInfo, refine_res, g] = nearest_pair_merge(movieInfo, refine_res, g, q);

%% module 3.2 merge broken tracks
[movieInfo, refine_res] = tracklets_broken_merge(movieInfo, refine_res, g, q);

end