function comMaps = refine_seedregion(comMapsInit, seg_threshold, cellnum)
% This function is specifically designed for refining seed region in missing cell module
vidComp = comMapsInit.vidComp; 
vidComp = imgaussfilt3(vidComp,[1 1 1]);
init_seed = comMapsInit.regComp;
init_seed_num = nnz(init_seed);
[~,~,K] = ind2sub(size(init_seed), find(init_seed));
[K_counts, ~] = histcounts(K);
max_slicearea = max(K_counts);

sph = strel('sphere', 2);
se = strel(sph.Neighborhood(:,:,3));% equal to strel('disk',2)
otherIdTerritory = comMapsInit.idComp>0 & comMapsInit.regComp==0;
otherIdTerritory = imdilate(otherIdTerritory, se);

[x,y,z] = ndgrid(-5:5,-5:5,-1:1);
se = (x.^2/25 + y.^2/25 + z.^2/1) <= 1;
search_area = imdilate(init_seed, se);
vidComp(~search_area) = min(vidComp(:));
vidComp(otherIdTerritory > 0) = min(vidComp(:));

if nnz(vidComp > seg_threshold) > 0.5 * init_seed_num
    seg_threshold = max(vidComp(:));
end
min_threshold = min(comMapsInit.vidComp(init_seed));
fg = false(size(vidComp));
for thres = seg_threshold:-2:min_threshold
    fg1 = vidComp > thres;
    fg2 = imfill(fg1,'holes');
    fg2(otherIdTerritory) = false;
    s = bwconncomp(fg2,18);
    if s.NumObjects == 0
        continue;
    end
    
    stats = regionprops(s, 'Area'); 
    reg_area = [stats.Area]; 
    [~, max_idx] = max(reg_area); 
    % the seed should have similar size to initial seed(max projection)
    if reg_area(max_idx) >= 0.5 * init_seed_num
        current_pixels = s.PixelIdxList{max_idx};
        [~,~,Z] = ind2sub(size(fg), current_pixels);
        [z_counts, ~] = histcounts(Z);
        [z_mode_tem, ~] = max(z_counts);
        if z_mode_tem < max_slicearea
            continue;
        end
        z_slices = unique(Z);
        fg(current_pixels) = 1;
        
        if isscalar(z_slices) && ~isscalar(K_counts)
            % we should check neighbors
            curr_mask = fg(:,:,z_slices);
            possible_zs = [];
            if z_slices > 1
                possible_zs(end+1) = z_slices - 1;
            end
            if z_slices < size(fg,3)
                possible_zs(end+1) = z_slices + 1;
            end
    
            for z_poss = possible_zs
                curr_vid = vidComp(:,:,z_poss);
                for curr_thres = ceil(max(curr_vid(:))):-2:ceil(min(curr_vid(:)))
                    candidate_slice = curr_vid > curr_thres;
                    candidate_slice = candidate_slice & curr_mask & ...
                                ~otherIdTerritory(:,:,z_poss);
                    s = bwconncomp(candidate_slice,8);
                    if s.NumObjects ~= 0
                        fg_curr = imdilate(candidate_slice, ones(3,3));
                        bg = imdilate(candidate_slice, ones(11,11));
                        bg2 = imdilate(candidate_slice, ones(9,9));
                        bg(bg2~=0) = false;
                        bg(otherIdTerritory(:,:,z_poss)) = false;
                        bg_vals = curr_vid(bg);
                        vals = curr_vid(fg_curr);
                        z_score = (mean(vals) - mean(bg_vals))/std(bg_vals)*sqrt(length(vals));
                        z_threshold = 2; % FDR control
                        if z_score >= z_threshold
                            fg(:,:,z_poss) = candidate_slice;
                        end
                        break;
                    end
                end
            end
        end
        
        for ii = 1:length(z_slices)
            slice_tem = fg(:,:,z_slices(ii));
            cc_z = bwconncomp(slice_tem, 4);        % 8-connectivity
            if cc_z.NumObjects > 1       % there are more than one region in a zslice
                stats_z = regionprops(cc_z, 'PixelIdxList', 'Area');
                [~, max_z_idx] = max([stats_z.Area]);
                pixels_2d = stats_z(max_z_idx).PixelIdxList;
                slice_refine = false(size(slice_tem));
                slice_refine(pixels_2d) = true;
                fg(:,:,z_slices(ii)) = slice_refine;
            end
        end
        if length(find(fg & init_seed)) <= 0.2*init_seed_num
            comMaps.regComp = false(size(init_seed));
            return;
        end
        break;
    end
end

%% test if there are false positive seeds
if all(fg(:)==0)
    comMaps.regComp = false(size(init_seed));
    return;
end    
bg = imdilate(fg, ones(5,5,2));
bg2 = imdilate(fg, ones(3,3,1));
bg(bg2~=0) = false;
vals = comMapsInit.vidComp(fg);
bg(comMapsInit.idComp > 0) = false;
bg_vals = comMapsInit.vidComp(bg);
%z_score = (mean(vals) - mean(bg_vals))/std(bg_vals)*sqrt(length(vals));
z_threshold = -norminv(0.01/cellnum); % FDR control

[z_score, mu, sigma] = orderstatistics_test(vals, bg_vals, std(bg_vals));
if z_score < z_threshold
    comMaps.regComp = false(size(init_seed));
    return;
end

comMaps = comMapsInit;
comMaps.regComp = fg;
comMaps.idComp(init_seed) = 0;
comMaps.idComp(fg) = min(comMapsInit.idComp(init_seed));

end