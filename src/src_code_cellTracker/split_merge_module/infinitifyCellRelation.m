function movieInfo = infinitifyCellRelation(movieInfo, root_cell_id, nei_cell_ids)
% remove the neighborhood relationship among root_cell_id and other cells
% included in nei_cell_ids

% no need to update CDist_i2j and CDist_j2i
f0 = movieInfo.frames(root_cell_id);
for i=1:length(nei_cell_ids)
    if nei_cell_ids(i) > 0 && nei_cell_ids(i) <= numel(movieInfo.frames)
        f1 = movieInfo.frames(nei_cell_ids(i));
        if f1>f0
            od = find(movieInfo.nei{root_cell_id}==nei_cell_ids(i));
            if ~isempty(od)
                movieInfo.CDist{root_cell_id}(od) = 1000;
                movieInfo.Cij{root_cell_id}(od) = inf;
                
                od = movieInfo.preNei{nei_cell_ids(i)}==root_cell_id;
                movieInfo.Cji{nei_cell_ids(i)}(od) = inf;
            end
        elseif f1<f0
            od = find(movieInfo.nei{nei_cell_ids(i)}==root_cell_id);
            if ~isempty(od)
                movieInfo.CDist{nei_cell_ids(i)}(od) = 1000;
                movieInfo.Cij{nei_cell_ids(i)}(od) = inf;
                
                od = movieInfo.preNei{root_cell_id}==nei_cell_ids(i);
                movieInfo.Cji{root_cell_id}(od) = inf;
            end
        end
    end
end

end