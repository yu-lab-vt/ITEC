function [possible_neis, neis_PorK_frame] = ...
    extractParentsOrKidsGivenCell(movieInfo, candidate_reg, ...
    candidate_frame, frame4findNeighbors, parent_flag)
% get the valid parents or kids for a given cell in the missed_frame
% neis_PorK_frame:
% invalid_locs: is the invalid node should be removed
possible_neis = neiExtract(movieInfo, candidate_reg, frame4findNeighbors);
% problem: do we need to make sure the parent or kid's best neighbor in the
% missed frame is just the candidate cell?
neis_PorK_frame = zeros(length(possible_neis),1);
consider_bestOv_nei_only = true;
if parent_flag
    preFlag = false;
else
    preFlag = true;
end
for i=1:length(possible_neis)
    bestNei = bestOvNei(possible_neis(i), movieInfo, candidate_frame, preFlag);
    best_Nei_family_f = nan;
    if ~isnan(bestNei)
        if parent_flag
            bestNei_family = movieInfo.kids{possible_neis(i)};
        else
            bestNei_family = movieInfo.parents{possible_neis(i)};
        end
        if ~isempty(bestNei_family)
            best_Nei_family_f = movieInfo.frames(bestNei_family);
        end
    end
    if bestNei ~= candidate_reg && consider_bestOv_nei_only
        possible_neis(i) = 0;
    end
    
    % if this neighbor has a kid in testing frame
    if best_Nei_family_f == candidate_frame
        best_Nei_family_f = nan;
    end
    neis_PorK_frame(i) = best_Nei_family_f;
end
neis_PorK_frame(possible_neis==0) = [];
possible_neis(possible_neis==0) = [];

% remove the isolated regions
track_ids = movieInfo.particle2track(possible_neis, 1);
possible_neis(isnan(track_ids)) = [];
neis_PorK_frame(isnan(track_ids)) = [];

if length(possible_neis) < 2
    return;
end

end