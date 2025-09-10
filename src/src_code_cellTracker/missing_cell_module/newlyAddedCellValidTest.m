function [flag, regVoxIdx] = newlyAddedCellValidTest(append_idx, append_frame, ...
    adj_cell_id, parent_kid_vec, movieInfo, refine_res, vidMap, eigMaps, ...
    comMaps, g, q)
% there are multiple cases that are valid for an newly found cell
% 1. a1->miss->a3
% 2. a1->miss,b->a3
% 3. a1,b1->miss,b2->a3,b3
% 4. a1,b1->miss->a3,b3
% 5. a1+b1->miss,b2->a3+b3
% 6. a1->miss+noise_bright_region->a3 (try split)
% 7. a1+b1->a2+b2_half,half_missing->a3,b3
% PS: '+' means merged region, ',' means independent region
% case 1 and 4 has not region to merge
[f_base, basecost1, basecost2] = parentKidValidLinkTest(append_idx, ...
    append_frame, parent_kid_vec, movieInfo, refine_res, g);
flag = [0, 0]; % [case_id, true/false]
regVoxIdx = [];
if isempty(adj_cell_id)% case 1 and 4
    % case 1
    if f_base
        flag = [1, 1];
    else % case 4 and 6
        % first check case 6: the region can be split by principal
        % curvauture. The processing steps are exactly the same as the
        % function 'segmentCurrentRegion.m'.
        if q.splitRegionInTracking % if we consider case 6
            [L, n] = bwlabeln(comMaps.newIdComp, q.neiMap);
            % remove invalid seeds first
            S = regionprops3(L, 'Volume');
            inval_ids = find([S.Volume] <= q.minSeedSize);
            if ~isempty(inval_ids)
                invalidMap = ismember(L, inval_ids);
                L(invalidMap) = 0;
                n = n - length(inval_ids);
            end
            % find valid seeds which covered by intial seed map
            fg_seeds = unique(L(comMaps.init_seed_map & L>0));
            if n > length(fg_seeds) && ~isempty(fg_seeds)
                % rebuild seed map to detect the true region
                fg_seed_map = ismember(L, fg_seeds);
                bg_seed_map = L>0 & ~fg_seed_map;
                L(fg_seed_map) = 1;
                L(bg_seed_map) = 2;
                bg2sink = false;
                newLabel = regionGrow(L, comMaps.score3dMap, ...
                    comMaps.fmapComp, q.growConnectInRefine, q.cost_design, bg2sink);
                new_append_idx = comMaps.linerInd(newLabel == 1);
                f_base = parentKidValidLinkTest(new_append_idx, append_frame, ...
                    parent_kid_vec, movieInfo, refine_res, g);
            end
        else
            f_base = false;
            new_append_idx = [];
        end
        if f_base
            flag = [6, 1];
            regVoxIdx = new_append_idx;
        elseif ~isnan(parent_kid_vec(1)) && ~isnan(parent_kid_vec(2))
            % case 4: TOO RARE, so we only check it loosely with a strict
            % criterion 
            adj_pk_vec = multiNeis_check(parent_kid_vec, append_idx, movieInfo, refine_res);
            if ~isempty(adj_pk_vec)
                % temporally change
                movieInfo.voxIdx{adj_pk_vec(1)} = cat(1, ...
                    movieInfo.voxIdx{adj_pk_vec(1)}, movieInfo.voxIdx{parent_kid_vec(1)});
                movieInfo.voxIdx{adj_pk_vec(2)} = cat(1, ...
                    movieInfo.voxIdx{adj_pk_vec(2)}, movieInfo.voxIdx{parent_kid_vec(2)});
                f_app = parentKidValidLinkTest(append_idx, append_frame, ...
                    adj_pk_vec, movieInfo, refine_res, g);
            else
                f_app = false;
            end
            if f_app
                flag = [4, 1];
            else
                flag = [4, 0];
            end
        else
            flag = [1, 0];
        end
    end
    
else % case 2 3 and 5
    append_idxPlus = cat(1, movieInfo.voxIdx{adj_cell_id}, append_idx);
    % case 2: should be smaller than baseline cost
    if isempty(movieInfo.parents{adj_cell_id}) && ...
            isempty(movieInfo.kids{adj_cell_id})
        [f_app, c1, c2] = parentKidValidLinkTest(append_idxPlus, append_frame, ...
            parent_kid_vec, movieInfo, refine_res, g);
        if f_app
            if (c1<=basecost1 && c2<=basecost2) || (~f_base)
                % sub-case 1: cost become smaller
                % sub-case 2: both bad, combined better
                flag = [2, 1];
            else
                flag = [1, 1];
            end
        elseif f_base
            flag = [1, 1];
        else
            flag = [2, 0];
        end
    % case 3 and 5
    else
        both_parents = movieInfo.parents{adj_cell_id}; % at most one
        if ~isnan(parent_kid_vec(1))
            both_parents = cat(1,both_parents, parent_kid_vec(1));
        end
        both_kids = movieInfo.kids{adj_cell_id}; % at most one
        if ~isnan(parent_kid_vec(2))
            both_kids = cat(1,both_kids, parent_kid_vec(2));
        end
        
        if isscalar(both_parents) && isscalar(both_kids)
            % scenario 5: both_parent can jump to both_kid; merged region
            % can link to both of them.
            [f_app1, m1,m2] = parentKidValidLinkTest(append_idxPlus, append_frame, ...
                [both_parents, both_kids], movieInfo, refine_res, g);
            % scenario 7: there is "another region" have not been considered.
            % If we add that region, both parents->merged region->both kid
            % + the "another region".
            f_app2 = multiParentsKidsValidLinkTest(append_idxPlus, append_frame, ...
                [both_parents, both_kids], [m1,m2], movieInfo, refine_res, g);
            if f_app1 || f_app2
                flag = [5, 1];
            elseif f_base
                flag = [1, 1];
            else
                flag = [5, 0];
            end
        % scenario 3: merging can link to both parents/kids, splitting can
        % link to split parents/kids
        else % either two kids or two parents
            p_flag = false;
            if length(both_parents) == 2
                parent_side = true;
                [p_flag, regVoxIdx] = mergeSplitBothValid(both_parents, append_idxPlus,...
                    append_frame, f_base, movieInfo, refine_res, vidMap,...
                    eigMaps, parent_side, g, q);
            end
            k_flag = false;
            if p_flag
                if isempty(regVoxIdx)
                    flag = [1, 1];
                else
                    flag = [3, 1];
                end
            else
                if length(both_kids) == 2
                    parent_side = false;
                    [k_flag, regVoxIdx] = mergeSplitBothValid(both_kids, append_idxPlus,...
                        append_frame, f_base, movieInfo, refine_res, vidMap,...
                        eigMaps, parent_side, g, q);
                end
                if k_flag 
                    if isempty(regVoxIdx)
                        flag = [1, 1];
                    else
                        flag = [3, 1];
                    end
                end
            end
            if flag(1) == 0 % haven't decide yet
                if f_base
                    flag = [1, 1];
                else
                    flag = [3, 0];
                end
            end
        end
    end
end

end