function costs = arc_cost_in_track(movieInfo, track_id, split_flag, max_jump)

% For a given track, this function extract the arc costs in this track.
% max_jump indicates we neglect the arcs jump over max_jump frames

if nargin == 2
    split_flag = false;
    max_jump = 1;% only consider arcs linking nodes in adjacent frames
end
if nargin == 3
    max_jump = 1;% only consider arcs linking nodes in adjacent frames
end
costs = [];
node_ids = movieInfo.tracks{track_id};
if length(node_ids) < 2
    return;
end

frames = movieInfo.frames(node_ids);

if split_flag
    error('Have not been implemented!');
else
    jumps = frames(2:end) - frames(1:end-1);
    if ~isempty(find(jumps<1,1))
        warning('track have not been sorted');
        [frames, od] = sort(frames,'ascend');
        node_ids = node_ids(od);
        jumps = frames(2:end) - frames(1:end-1);
    end
    node_ids(jumps > max_jump) = [];
    if length(node_ids) < 2
        return;
    end
    costs = zeros(length(node_ids)-1, 1);
    for i=1:length(node_ids)-1
        kid = movieInfo.kids{node_ids(i)}; % one and only one
        costs(i) = movieInfo.Cij{node_ids(i)}(movieInfo.nei{node_ids(i)}==kid);
    end
end