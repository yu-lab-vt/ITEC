function [movieInfo, refine_res, g] = nearest_pair_merge(...
    movieInfo, refine_res, g, q)

%% This module mainly handle broken tracks by checking the nearest tracks
% and refine cell regions

broken_tracks = struct('track_heads',[],'track_tails',[], 'heads_nei', [], ...
    'tails_nei', [], 'heads_track_id', [], 'tails_track_id', [], ...
    'heads_nei_track_id', [], 'tails_nei_track_id', []);

% 1.0 use one to one linking 
[~, g, dat_in] = trackGraphBuilder_cell(movieInfo, g);
movieInfo = mccTracker(dat_in, movieInfo, g);
movieInfo = mergeBrokenTracks(movieInfo, g, q);
% 1.1 find head and tail of tracks
track_heads = find(cellfun(@length, movieInfo.parents)==0 & cellfun(@length, movieInfo.kids)~=0 ...
                    & movieInfo.frames ~= min(movieInfo.frames));
track_tails = find(cellfun(@length, movieInfo.kids)==0 & cellfun(@length, movieInfo.parents)~=0 ...
                    & movieInfo.frames ~= max(movieInfo.frames));
track_heads(track_heads>length(movieInfo.xCoord)) = [];
track_tails(track_tails>length(movieInfo.xCoord)) = [];
broken_tracks.track_heads = track_heads;
broken_tracks.track_tails = track_tails;

movieInfo.track_id = zeros(numel(movieInfo.xCoord),1);
for i = 1:length(movieInfo.tracks)
    movieInfo.track_id(movieInfo.tracks{i}) = i; 
end

% 1.2 find nearest neighbor
nei_paras.im_resolution = q.im_resolution;
nei_paras.max_nei = 1;               
nei_paras.max_tracks_length = 10;
broken_tracks.heads_track_id = movieInfo.track_id(track_heads);
broken_tracks.tails_track_id = movieInfo.track_id(track_tails);
broken_tracks.heads_nei = cell(numel(broken_tracks.track_heads),1);
broken_tracks.tails_nei = cell(numel(broken_tracks.track_tails),1);
broken_tracks.heads_nei_track_id = cell(numel(broken_tracks.track_heads),1);
broken_tracks.tails_nei_track_id = cell(numel(broken_tracks.track_tails),1);
for i = 1:length(track_heads)
    broken_tracks.heads_nei{i} = findNeighbor(movieInfo, track_heads(i), nei_paras, 0);
    broken_tracks.heads_nei_track_id{i} = movieInfo.track_id(broken_tracks.heads_nei{i});
end
for i = 1:length(track_tails)
    broken_tracks.tails_nei{i} = findNeighbor(movieInfo, track_tails(i), nei_paras, 0);
    broken_tracks.tails_nei_track_id{i} = movieInfo.track_id(broken_tracks.tails_nei{i});
end

% 1.3 match with neighbors
% match_list:[head_id, tail_id, broken_track_id, match_nei_id]
match_nums = 0;
match_list = zeros(length(track_heads)*nei_paras.max_nei,5);
% case 1.3.1 the head and tail are in the same track
for i = 1:length(track_heads)
    common_id = find(broken_tracks.tails_track_id == broken_tracks.heads_track_id(i));
    if isempty(common_id)
        continue;
    else
        match_id = intersect(broken_tracks.heads_nei_track_id{i},broken_tracks.tails_nei_track_id{common_id});
        match_id = match_id(match_id~=0);
        kk = length(match_id);
        match_list(match_nums+1:match_nums+kk,:) = [track_heads(i)*ones(kk,1), ...
            track_tails(common_id)*ones(kk,1),broken_tracks.heads_track_id(i)*ones(kk,1),match_id,ones(kk,1)];
        match_nums = match_nums + kk;
    end
end
%case 1.3.2 the head and tail are in different tracks
for i = 1:length(track_heads)
    head_nei_id = broken_tracks.heads_nei_track_id{i};
    [~,tail_flag] = ismember(head_nei_id,broken_tracks.tails_track_id);
    tail_flag = tail_flag(tail_flag~=0);
    tail_nei_id = broken_tracks.tails_nei_track_id(tail_flag);
    for j = 1:length(tail_flag)
        if any(tail_nei_id{j} == broken_tracks.heads_track_id(i))
            match_list(match_nums+1,:) = [track_heads(i),track_tails(tail_flag(j)),...
                      broken_tracks.heads_track_id(i),broken_tracks.tails_track_id(tail_flag(j)),2];
            match_nums = match_nums + 1;
        end
    end
end
match_list = match_list(1:match_nums,:);

% 1.4 test if should be merged
merge_flag = zeros(match_nums,1);
for i = 1:size(match_list,1)
    track_match = tracks_frame_match(movieInfo, match_list(i,:));
    merge_flag(i,1) = nearest_pair_merge_test(movieInfo,track_match,nei_paras);  
end
match_list = match_list(find(merge_flag),:);

% 1.5 handle conflict
[~, ~, idx2] = unique(match_list(:,2));
counts2 = find(accumarray(idx2, 1)>1);
del_list = [];
for jj = 1:length(counts2)
    conflict_situ = match_list(idx2 == counts2(jj), :);
    if any(conflict_situ(:,5)==1)
        del_list = [del_list,find(idx2 == counts2(jj)&match_list(:,5)==2)];
    else
    % both case 1.3.2
    end
end
[~, ~, idx1] = unique(match_list(:,1));
counts1 = find(accumarray(idx1, 1)>1);
for jj = 1:length(counts1)
    conflict_situ = match_list(idx1 == counts1(jj), :);
    if any(conflict_situ(:,5)==1)
        del_list = [del_list,find(idx1 == counts1(jj)&match_list(:,5)==2)];
    else
    % both case 1.3.2
    end
end
match_list(del_list,:) = [];

% 2 update movieInfo
reg4upt = cell(size(match_list,1),1);
for i = 1:size(match_list,1)
    track_match = tracks_frame_match(movieInfo, match_list(i,:));
    mergeReg = num2cell(track_match,2);
    [refine_res, movieInfo, megReg] = mergedRegGrow(mergeReg, ...
            refine_res, movieInfo);
    reg4upt{i} = megReg(:);
end
reg4upt = cat(1, reg4upt{:});
[movieInfo, refine_res, g] = movieInfo_update(movieInfo, ...
    refine_res, reg4upt, g);
end