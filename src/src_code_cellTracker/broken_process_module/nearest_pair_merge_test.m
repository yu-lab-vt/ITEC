function merge_flag = nearest_pair_merge_test(movieInfo,track_match,nei_paras)

%% This function mainly test if broken tracks should be merged

if size(track_match,1) >= nei_paras.max_tracks_length       % too long tracks
    merge_flag = 0;
    return;
end
track_nei_coord = movieInfo.orgCoord(track_match(:,1),:);
track_broken_coord = movieInfo.orgCoord(track_match(:,2),:);
im_resolution = nei_paras.im_resolution;
test_flag = zeros(size(track_match,1),1);
for ii = 1:size(track_match,1)
    r = ((numel(movieInfo.voxIdx{track_match(ii,1)})+...
        numel(movieInfo.voxIdx{track_match(ii,2)}))*3*prod(im_resolution)/4/pi)^(1/3);
    test_flag(ii,:) = (1.2*r)>norm((track_nei_coord(ii,:) - track_broken_coord(ii,:)).*im_resolution);
end
merge_flag = all(test_flag);

end