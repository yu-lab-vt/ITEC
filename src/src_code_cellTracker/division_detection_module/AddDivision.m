function movieInfo_new = AddDivision(embryo_vid, movieInfo, q)

%% This function is to detect division
% INPUT:
%     embryo_vid: original 3D data
%     movieInfo:results of tracking
%     q:parameters of tracking
% OUTPUT:
%     movieInfo_new: new results of tracking

%% parameter setting
fprintf('--------------------Division Detection--------------------\n');
paras.im_resolution = q.im_resolution;
paras.max_nei = q.max_nei;        % max neighbor can find
paras.size_ratio = 3;             % max size ratio of two children
paras.child2parent_ratio = 0.8;   % maximum child to parent ratio
paras.data_size = size(embryo_vid{1});
paras.chi_thres = chi2inv(q.division_thres,3);

%% find division pairs
detect_divPair = candidate_divDetection(movieInfo, paras);

%% build new tracks
movieInfo_new = movieInfo;
for ii = 1:size(detect_divPair,1)
    if mod(ii,1000) == 0
        fprintf('%d/%d\n', ii, size(detect_divPair,1));
    end
    parent_id = detect_divPair(ii,1);
    child1_id = detect_divPair(ii,2);
    child2_id = detect_divPair(ii,3);

    parent_track = movieInfo.particle2track(parent_id,1);
    child1_track = movieInfo.particle2track(child1_id,1);
    child2_track = movieInfo.particle2track(child2_id,1);
    
    if parent_track == child1_track
        % parent connects to child1, now add to child2
        movieInfo_new = mergeParent2ChildTrack...
            (movieInfo_new, parent_id, child2_id, child2_track);
    else 
        % parents are not connected to any child
        movieInfo_new = mergeParent2ChildTrack...
            (movieInfo_new, parent_id, child1_id, child1_track);
        movieInfo_new = mergeParent2ChildTrack...
            (movieInfo_new, parent_id, child2_id, child2_track);
    end
end
end