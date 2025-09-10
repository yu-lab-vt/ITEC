function out_seeds = seedRefine_intensity(vidMap, fg_idx, fg_frame, ...
    seeds_idx, seeds_frame)
% remove voxes in seeds that are too dim or bright
l_c = 0.1;
r_c = 0.9;
if iscell(seeds_idx) % multiple seeds
    if length(seeds_frame) == 1
        seeds_frame = seeds_frame + zeros(numel(seeds_idx), 1);
    end
    
    out_seeds = cell(numel(seeds_idx), 1);
    for i=1:numel(seeds_idx)
        seed_vals = sort(vidMap{seeds_frame(i)}(seeds_idx{i}),'ascend');
        lb = seed_vals(max(round(l_c*length(seed_vals)), 1));
        ub = seed_vals(min(round(r_c*length(seed_vals)), length(seed_vals)));
        i_idx = intersect(seeds_idx{i}, fg_idx);
        i_vals = vidMap{fg_frame}(i_idx);
        
        out_seeds{i} = i_idx(i_vals>lb & i_vals<ub);
    end
else % one seed
    seed_vals = sort(vidMap{seeds_frame}(seeds_idx),'ascend');
    lb = seed_vals(max(round(l_c*length(seed_vals)), 1));
    ub = seed_vals(min(round(r_c*length(seed_vals)), length(seed_vals)));
    i_idx = intersect(seeds_idx, fg_idx);
    i_vals = vidMap{fg_frame}(i_idx);
    
    out_seeds = i_idx(i_vals>lb & i_vals<ub);
end
end