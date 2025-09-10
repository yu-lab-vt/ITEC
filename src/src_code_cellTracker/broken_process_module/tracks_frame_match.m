function track_match = tracks_frame_match(movieInfo, match_pair)

%% This function mainly matchs two tracks according to frames

tm_start = movieInfo.frames(match_pair(1,1));
tm_end = movieInfo.frames(match_pair(1,2));
nei_start = find(movieInfo.frames(movieInfo.tracks{match_pair(1,4)}) == tm_start);
nei_end = find(movieInfo.frames(movieInfo.tracks{match_pair(1,4)}) == tm_end);
broken_start = find(movieInfo.frames(movieInfo.tracks{match_pair(1,3)}) == tm_start);
broken_end = find(movieInfo.frames(movieInfo.tracks{match_pair(1,3)}) == tm_end);
track_nei = movieInfo.tracks{match_pair(1,4)}(nei_start:nei_end);
track_broken = movieInfo.tracks{match_pair(1,3)}(broken_start:broken_end);
track_nei_t = movieInfo.frames(track_nei);
track_broken_t = movieInfo.frames(track_broken);
[~, idxNei, idxBroken] = intersect(track_nei_t, track_broken_t);
track_match = [track_nei(idxNei), track_broken(idxBroken)];

end