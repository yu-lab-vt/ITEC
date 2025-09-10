function [refine_res, movieInfo, reg4upt, mg_sp_num] = regionRefresh(...
    movieInfo, refine_res, vidMap, g, eigMaps, q)
% test all one2multiple or multiple2one linking, see if we should separate
% or segment some region
%INPUT:
% movieInfo: all information about segmentation and tracks
% g: parameters for linking
% refine_res: cells containing the label maps
% vidMap: the original images(cells each of which corresponds to one frame)
% simple_merge: simply label the regions for merging as the same index
%OUTPUT:

% contact: ccwang@vt.edu, 03/04/2020

% 1: merge the current node's parents
% 2: merge the current node's kids
% 3: separate the current node based on its parents
% 4: separate the current node based on its kids
merge_parents = 1;
merge_kids = 2;
sep_by_parents = 3;
sep_by_kids = 4;

% one more evidence: the track has two far away regions in one frame
% label_maps = cell(numel(refine_res), 1);
% for i=1:numel(refine_res)
%     [label_maps{i}, n1] = bwlabeln(refine_res{i}>0, 6);
% end
%track_len = cellfun(@length, movieInfo.tracks);
%[~, od] = sort(track_len, 'descend');
merge_cnt = 0;
sep_cnt = 0;
reg4upt = cell(numel(movieInfo.tracks), 1);
for i=1:numel(movieInfo.tracks)
    % fprintf('processing %d/%d tracks, id:%d\n', i, numel(movieInfo.tracks),i);
    cur_track = movieInfo.tracks{i};
    if length(cur_track)<2
        continue;
    end
    [res_vec, nodes_inconsistent] = trackMergeTest(i, movieInfo, refine_res, vidMap, g, ...
        eigMaps, q);

    mergeReg = cell(size(res_vec,1), 1);
    merge_error_prob = zeros(size(res_vec,1), 1); % the smaller, the better
    m_cnt = 0;
    seperateReg = cell(size(res_vec,1), 1);
    s_cnt = 0;
    for j = 1:size(res_vec,1)
        switch res_vec(j,2)
            case merge_parents
                m_cnt = m_cnt + 1;
                mergeReg{m_cnt} = sort(movieInfo.parents{res_vec(j,1)})';
                merge_error_prob(m_cnt) = res_vec(j,3);
            case merge_kids
                m_cnt = m_cnt + 1;
                mergeReg{m_cnt} = sort(movieInfo.kids{res_vec(j,1)})';
                merge_error_prob(m_cnt) = res_vec(j,3);
            case sep_by_parents
                s_cnt = s_cnt + 1;
                seperateReg{s_cnt} = [res_vec(j,1); sort(movieInfo.parents{res_vec(j,1)})]';
            case sep_by_kids
                s_cnt = s_cnt + 1;
                seperateReg{s_cnt} = [res_vec(j,1); sort(movieInfo.kids{res_vec(j,1)})]';
            otherwise
                error('un-designed case');
        end
    end
    mergeReg = mergeReg(1:m_cnt);
    merge_error_prob = merge_error_prob(1:m_cnt);
    seperateReg = seperateReg(1:s_cnt);

    [mergeReg, seperateReg, f_merge] = conflict_decision_handle( ...
        mergeReg, seperateReg, nodes_inconsistent);
    %[mergeReg, seperateReg, f_merge] = xorCells(mergeReg, seperateReg, nodes_must_merge);
    merge_error_prob = merge_error_prob(f_merge);
    [refine_res, movieInfo, sepReg, newlyMerge] = separateRegion(...
        seperateReg, vidMap, refine_res, movieInfo, eigMaps, g, q);
    if ~isempty(newlyMerge)
        %some region cannot be split, remember this decision and do not split
        % them anymore
        if ~isempty(mergeReg)
            mergeReg = cat(1, mergeReg, newlyMerge);
            merge_error_prob = cat(1, merge_error_prob, ...
                0.01+zeros(numel(newlyMerge),1));
        else
            mergeReg = newlyMerge;
            merge_error_prob = 0.01+zeros(numel(newlyMerge),1);
        end
    end
    if numel(mergeReg) ~= length(merge_error_prob)
        error('merge_error_prob length is not consistent with mergeReg');
    end
    [refine_res, movieInfo, megReg] = mergedRegGrow(mergeReg, ...
        refine_res, movieInfo, merge_error_prob, g.stableNodeTest);

    merge_cnt = merge_cnt + numel(mergeReg);
    sep_cnt = sep_cnt + numel(seperateReg);
    reg4upt{i} = cat(1, megReg(:), sepReg(:));
end
reg4upt = cat(1, reg4upt{:});
mg_sp_num = [merge_cnt, sep_cnt];

end