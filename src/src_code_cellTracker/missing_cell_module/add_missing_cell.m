function [movieInfo, refine_res, thresholdMaps, added_cell_id] = ...
    add_missing_cell(movieInfo, refine_res, embryo_vid, g, ...
    thresholdMaps, eigMaps, q)
% for the (1)jump, (2) end or start of the trace, test if there is missing
% note: we do not allow merge/split in current movieInfo

added_cell_id = cell(numel(movieInfo.xCoord), 1);
m = [0,0,0];
if ~isfield(movieInfo, 'node_tested_st_end_jump')
    movieInfo.node_tested_st_end_jump = zeros(numel(movieInfo.xCoord), 4);
end
for i=1:numel(movieInfo.xCoord)
    if mod(i,10000)==0
        fprintf('processing %d / %d \n', i, numel(movieInfo.xCoord));
    end
    cur_frame = movieInfo.frames(i);
    upt_ids = cell(3,1);
    %% for jump in a track
    if ~isempty(movieInfo.kids{i})
        if length(movieInfo.kids{i}) ~= 1
            error('current stage each cell has at most one kid.');
        end
        if movieInfo.frames(movieInfo.kids{i}) > cur_frame + 1 && ...
                movieInfo.node_tested_st_end_jump(i,3)~=movieInfo.kids{i}
            parent_kid_vec = [i, movieInfo.kids{i}];
            [movieInfo, refine_res, thresholdMaps, upt_ids{1}] = ...
                deal_missing_from_jump(...
                movieInfo, refine_res, embryo_vid,...
            thresholdMaps, parent_kid_vec, eigMaps, g, q);
        
            movieInfo.node_tested_st_end_jump(i,3)=movieInfo.kids{i};
            movieInfo.node_tested_st_end_jump(movieInfo.kids{i},4)=i;
            if ~isempty(upt_ids{1})
                m(1) = m(1)+1;
            end
        end
    end
    %% for stopping of a trajectory(NOTE single node are removed)
    % note kids/parents should not change in prvious functions
    if isempty(movieInfo.kids{i}) && cur_frame<numel(embryo_vid) && ...
            ~isempty(movieInfo.parents{i}) && g.detect_missing_head_tail ...
            && movieInfo.node_tested_st_end_jump(i,2)==0
        parent_kid_vec = [i, nan];
        [movieInfo, refine_res, thresholdMaps, upt_ids{2}] = ...
            deal_missing_from_jump(...
            movieInfo, refine_res, embryo_vid,...
            thresholdMaps, parent_kid_vec, eigMaps, g, q);
        movieInfo.node_tested_st_end_jump(i,2) = 1;
        if ~isempty(upt_ids{2})
            m(2) = m(2)+1;
        end
    end
    %% for starting of a trajectory
    % note kids/parents should not change in prvious functions
    if isempty(movieInfo.parents{i}) && cur_frame>1  && ...
            ~isempty(movieInfo.kids{i}) && g.detect_missing_head_tail ...
            && movieInfo.node_tested_st_end_jump(i,1)==0
        
        parent_kid_vec = [nan, i];
        [movieInfo, refine_res, thresholdMaps, upt_ids{3}] = ...
            deal_missing_from_jump(...
            movieInfo, refine_res, embryo_vid,...
            thresholdMaps, parent_kid_vec, eigMaps, g, q);
        movieInfo.node_tested_st_end_jump(i,1)=1;
        if ~isempty(upt_ids{3})
            m(3) = m(3)+1;
        end
    end
    added_cell_id{i} = cat(1, upt_ids{:});
end
added_cell_id = unique(cat(1, added_cell_id{:}));
fprintf('We added %d missing cells!\n', sum(m));
end