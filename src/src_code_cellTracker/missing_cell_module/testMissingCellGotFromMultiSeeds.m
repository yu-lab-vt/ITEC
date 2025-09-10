function [movieInfo,refine_res, thresholdMaps, upt_ids] = ...
    testMissingCellGotFromMultiSeeds(comMaps, pseudo_seed_label, ...
    parent_kid_vec, missed_frame, movieInfo,refine_res, thresholdMaps, embryo_vid, g)
% if we detected multiple cells with several seeds, we only test if they
% are compatible with its own parents/kids, if so, keep them, otherwise
% remove those bad ones
upt_ids = [];

for i=1:length(pseudo_seed_label)
    % first test if the region has kid/parent in miss_frame
    if ~isnan(parent_kid_vec(i,1))
        if ~isempty(movieInfo.kids{parent_kid_vec(i,1)})
            % at most one kid
            if missed_frame == movieInfo.frames(movieInfo.kids{parent_kid_vec(i,1)}(1))
                continue;
            end
        end
    end
    if ~isnan(parent_kid_vec(i,2))
        % at most one parent
        if ~isempty(movieInfo.parents{parent_kid_vec(i,2)})
            if missed_frame == movieInfo.frames(movieInfo.parents{parent_kid_vec(i,2)}(1))
                continue;
            end
        end
    end
    % if jump exist, test if newly detected region is good
    append_idx = comMaps.linerInd(comMaps.idComp == pseudo_seed_label(i));
    flag = parentKidValidLinkTest(append_idx, ...
        missed_frame, parent_kid_vec(i,:), movieInfo, refine_res, g);
    if flag
        [movieInfo, cell_id] = addNewCell2MovieInfo(movieInfo, ...
            append_idx, parent_kid_vec(i,:), missed_frame);
        refine_res{missed_frame}(append_idx) = cell_id;
        thresholdMaps{missed_frame}(append_idx) = round(quantile(...
                           embryo_vid{missed_frame}(append_idx),0.5));
        upt_ids = cat(1, upt_ids, cell_id);
    end
end
end