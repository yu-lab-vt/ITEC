function [movieInfo, refine_res] = tracklets_broken_merge(movieInfo, refine_res, g, q)

%% step1 use no jump tracking
movieInfo_Jump = movieInfo;
movieInfo_noJump = build_movieInfo_noJump(movieInfo);
[~, g, dat_in] = trackGraphBuilder_cell(movieInfo_noJump, g);
movieInfo = mccTracker(dat_in, movieInfo, g);

%% step2 use distance rather than overlap to link broken tracklets
%{
% step2.1 build distance distribution
intrack_distance = cell(numel(movieInfo.parents),1);
for i=1:numel(movieInfo.parents)
    if ~isempty(movieInfo.parents{i})
        parent_frame = movieInfo.frames(movieInfo.parents{i});
        child_frame = movieInfo.frames(i);
        xd = movieInfo.xCoord(movieInfo.parents{i});
        yd = movieInfo.yCoord(movieInfo.parents{i});
        zd = movieInfo.zCoord(movieInfo.parents{i});
        parent_loc = [xd yd zd];
        child_loc = [movieInfo.xCoord(i) movieInfo.yCoord(i) movieInfo.zCoord(i)];
        frame_shift = getNonRigidDrift(parent_loc, child_loc, parent_frame, child_frame, movieInfo.drift, g.driftInfo);
        intrack_distance{i} = norm(child_loc - parent_loc - frame_shift);
    end
end
intrack_distance = cat(1, intrack_distance{:});
phat = gamfit(intrack_distance);
%}
% step2.2 find tracklets head and tails
track_heads = find(cellfun(@length, movieInfo.parents) == 0);  
track_heads(track_heads > length(movieInfo.xCoord)) = [];  
track_tails = find(cellfun(@length, movieInfo.kids) == 0); 
track_tails(track_tails > length(movieInfo.xCoord)) = []; 
valid_ids = union(track_heads, track_tails); 

broken_heads = track_heads(movieInfo.frames(track_heads)~=min(movieInfo.frames));
broken_tails = track_tails(movieInfo.frames(track_tails)~=max(movieInfo.frames));
min_dists = cell(numel(broken_heads)+numel(broken_tails),1);
for i = 1:numel(broken_heads)
    [~, min_dists{i}] = findNeighbor(movieInfo, broken_heads(i), q, -1);
end
for i = 1:numel(broken_tails)
    [~, min_dists{i+numel(broken_heads)}] = findNeighbor(movieInfo, broken_tails(i), q, 1);
end
min_dists = cat(1,min_dists{:});
min_dists = min_dists(:,1);
phat = gamfit(min_dists(min_dists~=0));

% step2.3 build new movieInfo_tracklet
% these elements are enough for the tracklet based linking
movieInfo_trackLet=struct('xCoord',[],'yCoord',[], 'zCoord', [], ...
    'frames', [], 'CDist', [], 'Ci', [], 'nei',[], 'Cij',[], 'ovGamma', []);

movieInfo_trackLet.xCoord = movieInfo.xCoord(valid_ids);
movieInfo_trackLet.yCoord = movieInfo.yCoord(valid_ids);
movieInfo_trackLet.zCoord = movieInfo.zCoord(valid_ids);
movieInfo_trackLet.frames = movieInfo.frames(valid_ids);
movieInfo_trackLet.CDist = movieInfo.CDist(valid_ids);
movieInfo_trackLet.Ci = movieInfo.Ci(valid_ids);
movieInfo_trackLet.ovGamma = phat;

map = nan(length(movieInfo.xCoord), 1);
map(valid_ids) = 1:length(valid_ids);

movieInfo_trackLet.nei = cell(length(valid_ids), 1);
% remove kids that not a head of a track
valid_kids_map = false(length(movieInfo.xCoord), 1);
valid_kids_map(track_heads) = true;
movieInfo_trackLet.nei = cellfun(@(x) x(valid_kids_map(x)), ...
    movieInfo_trackLet.nei,'UniformOutput', false);

movieInfo_trackLet.Cij = cell(length(valid_ids), 1);
for i=1:numel(movieInfo_trackLet.nei)
    if movieInfo.frames(valid_ids(i)) < length(movieInfo.n_perframe) && ...
            ismember(valid_ids(i), track_tails)
        
        % find the nearest neighbor in the next time point
        bestNei = findBestOvPair(movieInfo, valid_ids(i));
        if isempty(bestNei) || ~ismember(bestNei, track_heads)
           continue;
        end
        movieInfo_trackLet.nei{i} = bestNei;

        cur_nei = map(movieInfo_trackLet.nei{i});% change to new id
        cur_nei = cur_nei(~isnan(cur_nei));
        movieInfo_trackLet.nei{i} = cur_nei;
        if ~isempty(cur_nei)

            jumpRatio = [1 0 0];
            jump_punish = ...
                jumpRatio(movieInfo_trackLet.frames(cur_nei)-...
                movieInfo_trackLet.frames(i));
            
            parent_frame = movieInfo_trackLet.frames(i);
            child_frame = movieInfo_trackLet.frames(cur_nei);
            xd = movieInfo_trackLet.xCoord(i);
            yd = movieInfo_trackLet.yCoord(i);
            zd = movieInfo_trackLet.zCoord(i);
            parent_loc = [xd yd zd];
            xd = movieInfo_trackLet.xCoord(cur_nei);
            yd = movieInfo_trackLet.yCoord(cur_nei);
            zd = movieInfo_trackLet.zCoord(cur_nei);
            child_loc = [xd yd zd];

            frame_shift = getNonRigidDrift(parent_loc, child_loc, parent_frame, child_frame, movieInfo.drift, g.driftInfo);
            movieInfo_trackLet.CDist{i} = norm(child_loc - parent_loc - frame_shift);

            movieInfo_trackLet.Cij{i} = overlap2cost(...
                movieInfo_trackLet.CDist{i}, phat, jump_punish);
        end
    end
end
% step2.4 mcc tracking
[~, g, dat_in] = trackGraphBuilder_cell(movieInfo_trackLet, g);
movieInfo_trackLet = mccTracker(dat_in, movieInfo_trackLet, g, false, false);

%% step3 use jump tracking
[~, g, dat_in] = trackGraphBuilder_cell(movieInfo_Jump, g);
movieInfo = mccTracker(dat_in, movieInfo, g);

%% step4 merge over-split cells using these new tracks
track_len = cellfun(@length, movieInfo_trackLet.tracks);
movieInfo_trackLet.tracks(track_len<2) = [];
% union tracks for merging
loopCnt = 0;
while true
    for j=1:numel(movieInfo_trackLet.tracks)
        if isempty(movieInfo_trackLet.tracks{j})
            continue;
        end
        track_ids = movieInfo.particle2track(valid_ids(...
            movieInfo_trackLet.tracks{j}),1);
        track_ids = track_ids(~isnan(track_ids));
        if isempty(track_ids)
            continue;
        end
        for k = j+1:numel(movieInfo_trackLet.tracks)
            if isempty(movieInfo_trackLet.tracks{k})
                continue;
            end
            track_ids_new = movieInfo.particle2track(valid_ids(...
                movieInfo_trackLet.tracks{k}),1);
            track_ids_new = track_ids_new(~isnan(track_ids_new));
            if ~isempty(intersect(track_ids, track_ids_new))
                movieInfo_trackLet.tracks{j} = union(...
                    movieInfo_trackLet.tracks{j}, ...
                    movieInfo_trackLet.tracks{k});
                movieInfo_trackLet.tracks{k} = [];
                track_ids = union(track_ids, track_ids_new);
            end
        end
    end
    track_len = cellfun(@length, movieInfo_trackLet.tracks);
    loopCnt = loopCnt + 1;
    if loopCnt > 3 || sum(track_len<2)==0
        break;
    end
    movieInfo_trackLet.tracks(track_len<2) = [];
end

mergeReg = {};
for i=1:numel(movieInfo_trackLet.tracks)
    cur_track = movieInfo_trackLet.tracks{i};
    cur_track = valid_ids(cur_track); % retrieve real ids
    % update tracks and pathCost (cost is not accurate since it is not important)
    track_ids = movieInfo.particle2track(cur_track,1); 
    tmp_track = [];
    for j = 1:length(track_ids)
        if isnan(track_ids(j))
            tmp_track = cat(1, tmp_track, cur_track(j));
        else
            if isempty(find(track_ids(1:j-1)==track_ids(j), 1))
                tmp_track = cat(1, tmp_track, ...
                    movieInfo.tracks{track_ids(j)});
            end
        end
    end
    tmp_track = unique(tmp_track);
    tmp_track = sort(tmp_track, 'ascend');
    tmp_tm = movieInfo.frames(tmp_track);
    unique_tm = unique(tmp_tm);
    for j = 1:length(unique_tm)
        indices = find(tmp_tm == unique_tm(j)); 
        % we should merge broken cells
        if length(indices) == 2
            mergeReg{end+1,1} = tmp_track(indices);
        elseif length(indices) > 2
            for k = 2:length(indices)
                mergeReg{end+1,1} = [tmp_track(indices(1)); tmp_track(indices(k))];
            end
        end
    end
end
[refine_res, movieInfo, megReg] = mergedRegGrow(mergeReg,...
            refine_res, movieInfo);
reg4upt = megReg(:);
[movieInfo, refine_res, ~] = movieInfo_update(movieInfo, refine_res, reg4upt, g);
end