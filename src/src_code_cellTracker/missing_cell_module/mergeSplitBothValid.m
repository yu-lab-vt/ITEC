function [flag, regVoxIdx] = mergeSplitBothValid(sep_ids, test_reg_idx, test_reg_f, ...
    splitTested, movieInfo, refine_res, vidMap,eigMaps, parent_side, g, q)
% test if the tested region is good for both merge and split
% parent_side == 1, this is testing two parents nodes
flag = false;
f1 = movieInfo.frames(sep_ids(1)); % adjacent cell's parent or kid
f2 = movieInfo.frames(sep_ids(2)); % newly detected cell's parent or kid
regVoxIdx = [];
if f1==f2
    both_idx = cat(1, movieInfo.voxIdx{sep_ids});
    p_k_frames = [f1,test_reg_f];
    p_f1 = voxIdxValidLinkTest(both_idx,  ...
        test_reg_idx, p_k_frames, movieInfo, refine_res, g);
    if p_f1
        if splitTested && g.reSplitTest == false
            flag = true;
        else % test if split can link to them
            gapMaps = [];
            [validSplit, regVoxIdx] = bisectValidTest(test_reg_idx, ...
                test_reg_f, movieInfo.voxIdx(sep_ids), ...
                f1, movieInfo, vidMap, refine_res, eigMaps, ...
                gapMaps, g, q);
            if ~validSplit
                % second try: use intersection as seed regions to separate
                gapBased = false;
                [validSplit, regVoxIdx] = bisectValidTest(test_reg_idx, ...
                    test_reg_f, movieInfo.voxIdx(sep_ids), ...
                    f1, movieInfo, vidMap, refine_res, eigMaps, ...
                    gapMaps, g, q, gapBased);
            end
            if validSplit
                % test the opposite direction
                if parent_side
                    opposite_node_adj = ...
                        movieInfo.kids{movieInfo.kids{sep_ids(1)}};
                    opposite_node_newAdded = ...
                        movieInfo.kids{sep_ids(2)};
                else
                    opposite_node_adj = ...
                        movieInfo.parents{movieInfo.parents{sep_ids(1)}};
                    opposite_node_newAdded = ...
                        movieInfo.parents{sep_ids(2)};
                end
                if max(length(opposite_node_adj), ...
                        length(opposite_node_newAdded))>1
                    error('current linking should has at most one parent/kid!');
                end
                if ~isempty(opposite_node_adj)
                    frames = [ test_reg_f, movieInfo.frames(opposite_node_adj)];
                    f_base_ajd = voxIdxValidLinkTest(regVoxIdx{1}, ...
                        movieInfo.voxIdx{opposite_node_adj}, frames, movieInfo, ...
                        refine_res, g);
                else
                    f_base_ajd = true;
                end
                f_base_added = false;
                if f_base_ajd 
                    if ~isempty(opposite_node_newAdded)
                        frames = [ test_reg_f, movieInfo.frames(opposite_node_newAdded)];
                        f_base_added = voxIdxValidLinkTest(regVoxIdx{2}, ...
                            movieInfo.voxIdx{opposite_node_newAdded}, frames, movieInfo, ...
                            refine_res, g);
                    else
                        f_base_added = true;
                    end
                end
                if f_base_ajd && f_base_added
                    flag = true;
                else
                    flag = false;
                end
            else
                flag = false;
            end
        end
    else
        flag = false;
    end
end
end