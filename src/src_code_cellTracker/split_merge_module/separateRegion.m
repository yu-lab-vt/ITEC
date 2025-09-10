function [refine_res, movieInfo, newly_reg, newly_merge] = separateRegion(...
    sepReg, vidMap, refine_res, movieInfo, eigMaps, g, q)
% region grow to merge several given seed regions
%INPUT:
% mergeReg: cells, each cell containing the regions that should be merged
% scoreMap: cells, each containing the score map for region grow
% refine_res: cells, label map of each frame
% movieInfo: information about cells and tracks
% simple_merge: simply label the regions for merging as the same index
%OUTPUT:

% ccwang@vt.edu, 03/04/2020

% connect = 4;
% cost_design = [1 2];
% smooth_sc = 1;
% shift = [5 5 2];
% smooth_sc = [5 3];
% shift = [3 3 1];
% cost_design = [1, 2];
% connect = 6;

sep_done = [];
newly_reg = cell(numel(sepReg), 1);
newly_merge = cell(numel(sepReg), 1);
max_label_cnt = numel(movieInfo.voxIdx);
for i=1:numel(sepReg)
    cur_reg = sepReg{i}(1);
    if find(sep_done == cur_reg, 1) %avoid duplicate split
        continue;
    end
    cur_frame = movieInfo.frames(cur_reg);
    cur_idx = movieInfo.voxIdx{cur_reg};
    real_id = refine_res{cur_frame}(movieInfo.voxIdx{cur_reg}(1));
    sep_frames = movieInfo.frames(sepReg{i}(2:end));
    if real_id + sum(movieInfo.n_perframe(1:cur_frame-1)) ~= cur_reg
        error('label wrong!');
    end
    if length(unique(sep_frames))>1
        continue;
    end
    base_ids = sepReg{i}(2:end);
    % test if we can split the current region
    if ~g.stableNodeTest || isinf(movieInfo.arc_avg_mid_std(cur_reg,4)) % ...
            % || sum(~isinf(movieInfo.arc_avg_mid_std(base_ids,4)))>=2 
            % The third condition in IF here is not needed. It has been 
            % considered in highOvEdges.m line 30-39.
        sep_idx = movieInfo.voxIdx(base_ids);
        % first try: use gap to separate it
        gapMaps = [];
        [validFlag, regVoxIdx] = bisectValidTest(cur_idx, ...
            cur_frame, sep_idx, sep_frames(1), movieInfo, vidMap, refine_res, eigMaps, ...
            gapMaps, g, q);
        if ~validFlag
            % second try: use intersection as seed regions to separate
            gapBased = false;
            [validFlag, regVoxIdx] = bisectValidTest(...
                cur_idx, cur_frame, sep_idx, sep_frames(1), movieInfo, ...
                vidMap, refine_res, eigMaps, gapMaps, g, q, gapBased);
        end
    else
        validFlag = false;
    end
    if ~validFlag % there is no way to split current region
        [movieInfo, merge_regs] = handleNonSplitReg(movieInfo, ...
            cur_reg, base_ids, g);
        newly_merge{i} = merge_regs;
        continue;
    end
    refine_res{cur_frame}(cur_idx) = 0;
    refine_res{cur_frame}(regVoxIdx{1}) = real_id;
    movieInfo.voxIdx{cur_reg} = regVoxIdx{1}; % no consider drift
    movieInfo.voxIdx = cat(1, movieInfo.voxIdx, regVoxIdx{2});
    movieInfo.frames = cat(1, movieInfo.frames, cur_frame);
    max_label_cnt = max_label_cnt + 1;
    if numel(movieInfo.voxIdx) ~= length(movieInfo.frames)...
            || max_label_cnt ~= length(movieInfo.frames)
        keyboard;
    end
    refine_res{cur_frame}(regVoxIdx{2}) = max_label_cnt;
    newly_reg{i} = nan(length(sepReg{i})-1,1);
    newly_reg{i}(1) = cur_reg;
    newly_reg{i}(2) = max_label_cnt;
    sep_done = cat(1, sep_done, cur_reg);
end

newly_reg = cat(1, newly_reg{:});
newly_reg(isnan(newly_reg)) = [];
newly_merge(cellfun(@isempty, newly_merge)) = [];
end