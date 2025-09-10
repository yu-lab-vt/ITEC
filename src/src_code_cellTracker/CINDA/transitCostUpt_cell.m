function movieInfo = transitCostUpt_cell(movieInfo, g)
%% This function is to update transition cost using existing trajectories using both precursors
% and ancestors
%
% correct drift and re-calculate calibrated field: vox and CDist
movieInfo = driftFromTracks(movieInfo,g);
% update the gamma distribution parameters
phatDist = getStdFromTracks_cell(movieInfo, g);
movieInfo.ovGamma = phatDist;
%% we update cost of all edges rather than part of them
movieInfo = upt_cost_with_Dist(movieInfo);
movieInfo = stable_arc_cost_extract(movieInfo, g);
fprintf('finish cost update!\n');

end