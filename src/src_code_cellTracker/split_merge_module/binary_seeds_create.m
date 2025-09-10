function [seedsMap, vflag] = binary_seeds_create(fgMap, gapMap3d, gapMap2d, ...
    baseRegIdx, min_seed_sz)
% 1. separate the foreground by removing gaps
% 2. given two regions(baseRegIdx), split the foreground based ont these
% two regions.
if nargin == 4
    min_seed_sz = 0;
end
% split connect components
if isempty(gapMap3d)
    [label_map,n] = bwlabeln(fgMap & ~gapMap2d, 6);
elseif isempty(gapMap2d)
    [label_map,n] = bwlabeln(fgMap & ~gapMap3d, 6);
else
    seedsMap = seed_map_gen(fgMap, gapMap3d, gapMap2d, min_seed_sz);
    [label_map,n] = bwlabeln(seedsMap, 6);
end
if n<2 
    vflag = false;
    seedsMap = [];
    return;
end

base_labels = nan(n, numel(baseRegIdx));% 
for j=1:numel(baseRegIdx)
    out_freq = frequency_cnt(label_map(baseRegIdx{j}));
    for k=1:size(out_freq,1)
        if out_freq(k,1) > 0
            base_labels(out_freq(k,1), j) = out_freq(k,2);
        end
    end
end
seedsMap = zeros(size(label_map));
all_seed_used = false(numel(baseRegIdx), 1);
for i = 1:n
    [v, od] = nanmax(base_labels(i,:));
    if ~isnan(v)
        seedsMap(label_map == i) = od;
        all_seed_used(od) = true;
    end
end
% if there is a based region that has no correponding region in root region
if ~any(all_seed_used == false)
    vflag = true;    
else
    vflag = false;
    seedsMap = [];
end
end