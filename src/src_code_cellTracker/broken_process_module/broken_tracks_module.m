function [movieInfo, refine_res, g] = broken_tracks_module(...
    movieInfo, refine_res, g, q)

%% This function is to merge broken tracks due to over-split

% This legacy module directly rewrites parents/kids after solving. Its local
% repair is disabled in constrained mode; regular iterations still optimize free nodes.
if isfield(movieInfo, 'lockedDetection') && any(movieInfo.lockedDetection)
    fprintf('Skip broken-track repair because manual locks are active.\n');
    return;
end

%% module 3.1 find nearest cell pairs and merge them
[movieInfo, refine_res, g] = nearest_pair_merge(movieInfo, refine_res, g, q);

%% module 3.2 merge broken tracks
[movieInfo, refine_res] = tracklets_broken_merge(movieInfo, refine_res, g, q);

end