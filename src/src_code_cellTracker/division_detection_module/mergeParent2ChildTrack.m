function movieInfo = mergeParent2ChildTrack(movieInfo, parent_id, child_id, child_track)

%% This function is to update movieInfo with division results
% INPUT:
%     movieInfo:results of tracking
%     parent_id:id of parent
%     child_id:id of child
%     child_track:track id of child
% OUTPUT:
%     movieInfo:new results of tracking

child_loc = find(movieInfo.tracks{child_track} == child_id);
if child_loc == 1
    movieInfo.parents{child_id} = parent_id;
    movieInfo.kids{parent_id} = [movieInfo.kids{parent_id};child_id];
    movieInfo.tracks{child_track} = [parent_id; movieInfo.tracks{child_track}];
elseif child_loc == 2
    movieInfo.parents{child_id} = parent_id;
    movieInfo.kids{parent_id} = [movieInfo.kids{parent_id};child_id];
    movieInfo.tracks{child_track} = [parent_id; movieInfo.tracks{child_track}(2:end)];
else
    error('Wrong case');
end
end