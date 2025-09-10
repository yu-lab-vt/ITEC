function [trajectories, costs, track_bf_merge, parents, kids] = ...
    mcc4mot_cell(detection_arcs,transition_arcs, append_arcs)
% The min-cost circulation formulation based MAP solver for multi-object
% tracking.
% INPUT: 
% Assuming we have n detections in the video, then
% detection_arcs: a n x 4 matrix, each row corresponds to a detection in the
% form of [detection_id, C_i^en, C_i^ex, C_i];
% transition_arcs: a m x 3 matrix, each row corresponds to a transition arc
% in the form of [detection_id_i, detection_id_j, C_i,j]
% NOTE that the id should be unique and in the range of 1 to n. Detailed 
% defintion can be found in the user manual.
% append_arcs: arcs that link pre-node to sink or src node to post node;
% those arcs allows cells to separate or merge

% OUTPUT:
% trajectories: cells containing the linking results; each cell contains a
% set of ordered detection ids, which indicate a trajectory
% costs: costs of these trajectories
% track_bf_merge: cells containing the trajectories before we merge some
% tracks
% parents: parent nodes of the current nodes
% kids: kid nodes of the current node
n = size(detection_arcs,1); 

m = n*3+size(transition_arcs,1) + length(find(~isnan(append_arcs(:,2:3))));

src_node = 1;
sink_node = 1; 
%sink_node = 2*n+2; % uncomment this if using successive shortest path
arcs = zeros(m,3); % with the dummy node 

pre_id = detection_arcs(:,1) * 2;
post_id = detection_arcs(:,1) * 2 + 1;
% entering arcs
arcs(1:n,1) = src_node; % tail: dummy node
arcs(1:n,2) = pre_id; % head 
arcs(1:n,3) = detection_arcs(:,2);

% exiting arcs
arcs(n+1:2*n,1) = post_id; % tail: dummy node
arcs(n+1:2*n,2) = sink_node; % head 
arcs(n+1:2*n,3) = detection_arcs(:,3);


% detection confidence
arcs(2*n+1:3*n,1) = pre_id; % tail: dummy node
arcs(2*n+1:3*n,2) = post_id; % head 
arcs(2*n+1:3*n,3) = detection_arcs(:,4);

% transition arcs
tr_arc_num = size(transition_arcs,1);
arcs(3*n+1:3*n+tr_arc_num,1) = transition_arcs(:,1)*2 + 1; % post nodes
arcs(3*n+1:3*n+tr_arc_num,2) = transition_arcs(:,2)*2; % pre nodes
arcs(3*n+1:3*n+tr_arc_num,3) = transition_arcs(:,3);

% append arcs linking pre-node to sink
cur_arc_start = 3*n+tr_arc_num + 1;
append_pre_valid = find(~isnan(append_arcs(:,2)));
append_pre_ids = append_arcs(append_pre_valid, 1) * 2;
cur_arc_end = cur_arc_start - 1 + length(append_pre_ids);

arcs(cur_arc_start:cur_arc_end,1) = append_pre_ids; % pre nodes
arcs(cur_arc_start:cur_arc_end,2) = sink_node; % sink
arcs(cur_arc_start:cur_arc_end,3) = append_arcs(append_pre_valid, 2);

% append arcs linking src to post nodes
cur_arc_start = cur_arc_end + 1;
append_post_valid = find(~isnan(append_arcs(:,3)));
append_post_ids = append_arcs(append_post_valid, 1) * 2 + 1;
cur_arc_end = cur_arc_start - 1 + length(append_post_ids);

arcs(cur_arc_start:cur_arc_end,1) = src_node; % src
arcs(cur_arc_start:cur_arc_end,2) = append_post_ids; % post nodes
arcs(cur_arc_start:cur_arc_end,3) = append_arcs(append_post_valid, 3);

if cur_arc_end~=m
    keyboard;
end
%% sucessive shortest path: min-cost flow based and slow (since matlab version)
% orgG = digraph(arcs(:,1),arcs(:,2),arcs(:, 3)+1e-5*rand(m,1));
% [res_G, pSet, costs] = successive_shortest_paths(orgG, src_node, ...
%     sink_node);
% [trajectories, track_bf_merge, parents, kids] = recover_paths_ssp_cell(...
%     res_G, numel(pSet), sink_node);
% return;

%% CINDA
tail = arcs(:,1)';
head = arcs(:,2)';
cost = arcs(:,3)';%+1e-5*rand(1,m);
it_flag = false;
if ~isempty(find(cost > floor(cost), 1))
    it_flag = true;
    cost = round(cost * 1e7); % assume integer cost
end
low = zeros(1,m);
acap = ones(1,m);


num_node = 2*n+1;
excess_node = 1; % only for circulation
excess_flow = 0; % only for circulation

num_arc = m;
scale = 12;

% num_node = 2*n+2;
% num_arc = m + 1;
% tail = [tail, 2*n+2];
% head = [head, 1];
% cost = [cost, 0];
% low = [low, 0];
% acap = [acap, n];
% call the manipulated cs2 function for min-cost circulation
[cost_all,~,~,~, track_vec] = cinda_mex(scale, num_node, num_arc, excess_node, excess_flow, tail, head, low, acap, cost);

if cost_all >= 0 || isempty(track_vec)
    warning(['Null trajectory set! Please check the cost design. ',...
        'Note that high detection confidence corresponds to negative arc cost.']);
    costs = 0;
    trajectories = {};
    return;
end
locs = find(track_vec<=0);
if length(track_vec) > locs(end)
    track_vec = track_vec(1:locs(end));
end
costs = track_vec(locs);
track_len = locs(2:end) - locs(1:end-1) - 1;
track_len = [locs(1)-1; track_len];
track_vec(locs) = [];
track_bf_merge = mat2cell(track_vec, track_len,1);
track_bf_merge = cellfun(@(x) unique(floor(x/2)), track_bf_merge, ...
    'UniformOutput',false);
% track_len = [locs(1)-1; track_len]/2;
% track_vec = track_vec(1:2:end)/2;
if it_flag
    costs = costs / 1e7;
end
% merge those related ones
parents = cell(n,1);
kids = cell(n,1);

for i=1:numel(track_bf_merge)
    % find the parent nodes and kid nodes for each cell
    for j=1:numel(track_bf_merge{i})-1
        kids{track_bf_merge{i}(j)} = cat(1, kids{track_bf_merge{i}(j)}, ...
            track_bf_merge{i}(j+1));
        parents{track_bf_merge{i}(j+1)} = cat(1, ...
            parents{track_bf_merge{i}(j+1)}, track_bf_merge{i}(j));
    end
end
% this part is slow, can be accelerated by separate into two forloop
trajectories = cell(numel(track_bf_merge),1);
merged_track_cnt = 0;
cell2track_id = nan(n,1);
for i=1:n
    if isnan(cell2track_id(i))
        merged_track_cnt = merged_track_cnt + 1;
        trajectories{merged_track_cnt} = i;
        cell2track_id(i) = merged_track_cnt;
    end
    uni_parent_track_id = unique(cell2track_id(parents{i}));
    if length(uni_parent_track_id) <= 1 
        cur_kid = kids{i}(isnan(cell2track_id(kids{i})));
        trajectories{cell2track_id(i)} = cat(1, ...
            trajectories{cell2track_id(i)}, cur_kid);
        cell2track_id(cur_kid) = cell2track_id(i);
    else
        merged_id = min(uni_parent_track_id);
        tmp_track = cat(1, ...
            trajectories{cell2track_id(parents{i})}, kids{i});
        trajectories(cell2track_id(parents{i})) = {[]};
        trajectories{merged_id} = tmp_track;
        cell2track_id(tmp_track) = merged_id;
    end
end

valid_track_id = cellfun(@length, trajectories)>1;
trajectories = trajectories(valid_track_id);
trajectories = cellfun(@unique, trajectories, 'UniformOutput', false);
fprintf('after merging, totally get %d tracks\n', numel(trajectories));
