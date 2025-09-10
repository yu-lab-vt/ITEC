function [mergeReg, seperateReg, f_merge] = conflict_decision_handle(...
        mergeReg, seperateReg, nodes_inconsistent)
% There may be conflict decisions, we can 1) syncronize conflict one (e.g. 
% a->b+c, b+d->e both exists, the decision should be the same;
% otherwise we should merge b,c,d) 2) remove both of them; 3) keep
% those should be merged (e.g. nodes_inconsistent); 3) 

% NOTE: 
% Two conditions have been avoied in highOvEdges.m, which are
% 1) a->b+c, a+d->b and 2) same as 1)
% Two conditions have been avoided in trackMergeTest.m, which are
% 1) a->b+c, b->d+e and 2) a+b->c, d+e->a




% step 1: detect a->b+c, b+d->e
nodes2split_cell  = cellfun(@(x) x(2:end), seperateReg, 'UniformOutput', false);

invalid_split_id = [];
for i=1:numel(mergeReg)
    ov_split_cell_id = nan(length(mergeReg{i}),1);
    for j=1:numel(mergeReg{i})
        found = cellfun(@(x) ~isempty(find(x==mergeReg{i}(j),1)), nodes2split_cell);
        ov_loc = find(found);
        if length(ov_loc) > 1
            error('we found a merge concatenating with two split!');
        end
        if ~isempty(ov_loc)
            ov_split_cell_id(j) = ov_loc;
        end
    end
    ov_split_cell_id = ov_split_cell_id(~isnan(ov_split_cell_id));
    if isempty(ov_split_cell_id)
       continue;
    end
    
    mergeReg{i} = unique(cat(2, mergeReg{i}, nodes2split_cell{ov_split_cell_id}));
    invalid_split_id = cat(1, invalid_split_id, ov_split_cell_id);
end
if ~isempty(invalid_split_id)
    seperateReg(invalid_split_id) = [];
end

% step 2: remove conflice ones while keeps those correct ones
[mergeReg, seperateReg, f_merge] = xorCells(mergeReg, seperateReg, nodes_inconsistent);