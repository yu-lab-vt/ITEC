function [movieInfo, movieInfo_noJump] = handleMergeSplitRegions(movieInfo, g)
% add multi-to-one or one-to-multi choices; for >1 regions that has high 
% overlapping ratios with one pre- or post- neighbor, add links for such
% region to src or sink such that one region can incident with >1 regions

% we first build a movieInfo with no jump
% noJumpAll: all linking has no jump; 
% noJump: no jump for spliting and merge
% none: consider jump
if strcmp(g.splitMergeHandle, 'noJumpAll')
    movieInfo_noJump = build_movieInfo_noJump(movieInfo);
end

% get the arcs about split/merge among regions
[dat_in_append, movieInfo_noJump] = highOvEdges(movieInfo_noJump, g);
% get the other arcs
[~, g, dat_in] = trackGraphBuilder_cell(movieInfo_noJump, g);
if ~isempty(dat_in_append)
    dat_in = cat(1, dat_in, dat_in_append);
end
% linking with new graph design and update movieInfo (not movieInfo_noJump)
movieInfo = mccTracker(dat_in, movieInfo, g);
end