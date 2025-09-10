function phatDist = getStdFromTracks_cell(movieInfo, g)

%% get the standard deviation from existing tracks
numTrajectories = numel(movieInfo.tracks);
validTrack = 0;
devDist = cell(numTrajectories,1);

for i=1:numTrajectories
    curTrack = movieInfo.tracks{i};
    if length(curTrack)<g.trackLength4var % only use those trajectories >=g.trackLength4var
        continue;
    end
    validTrack = validTrack+1;
    % estimate variance
    cur_dist = zeros(length(curTrack)-1, 1);
    
    for j=1:length(curTrack)-1
        cur_dist(j) = movieInfo.CDist{curTrack(j)}...
            ((movieInfo.nei{curTrack(j)}==curTrack(j+1)));
    end
    devDist{i} = cur_dist;
end
all_dev = cat(1, devDist{:});
all_dev(isnan(all_dev(:,1)) | isinf(all_dev(:,1)),:) = [];
phatDist = fitTruncGamma(all_dev);

end