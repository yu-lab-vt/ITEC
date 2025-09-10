function mat2csv(movieInfo, save_folder)

%% This function is to convert movieInfo to csv format
% INPUT:
%    movieInfo:tracking results
%    save_folder:path of tracking results

xCoord = movieInfo.xCoord;
yCoord = movieInfo.yCoord;
zCoord = movieInfo.zCoord;
frames = movieInfo.frames;
parents = movieInfo.parents;
kids = movieInfo.kids;
id = (1:length(xCoord))';
parentLengths = cellfun(@length, parents);
childLengths = cellfun(@length, kids);

if iscell(parents)
    parentsStr = nan(size(parents)); % 预分配字符串数组
    for i = 1:numel(parents)
        if ~isempty(parents{i})
            parentsStr(i) = parents{i}; % 尝试转换
        end
    end
else
    parentsStr = string(repmat({''}, size(xCoord)));
end

T = table(id, parentLengths, childLengths, frames, xCoord, yCoord, zCoord, ...
    parentsStr,'VariableNames', {'ID','incoming links','outgoing links', ...
    'frames','xCoord', 'yCoord', 'zCoord', 'parents'});
writetable(T, save_folder);

