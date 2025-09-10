function fg = refine_with_seedRegion(fg, seedRegion, minSize)

l = bwlabeln(fg, 6);
seed_ids = l(seedRegion>0);
seed_ids = mode(seed_ids(seed_ids>0)); % we should only keep the best connected component
fg = ismember(l, seed_ids);

% remove pixels with no upper neighbor or lower neighbor in z-direction
conn = zeros(3,3,3);
conn(2,2,2) = 1;
conn(2,2,1) = 1;
fg_noUp = imerode(fg, conn);
conn(2,2,1) = 0;
conn(2,2,3) = 1;
fg_noDown = imerode(fg, conn);
fg = fg_noUp | fg_noDown;
% dilate operation time in xy direction
% fg = imdilate(fg, strel('disk',1));
% remove regions that are too small
fg = bwareaopen(fg, minSize, 26);

end