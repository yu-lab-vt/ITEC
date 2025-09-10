function movieInfo = stable_arc_cost_extract(movieInfo, g)

% For any track, get the mean, median and std of its arc costs and save
% them for each node in the track.
% for the 4th element, default is inf, 1 means head, 2 means middle, 3
% means tail

maxcost = (norminv(0.5*movieInfo.jumpRatio(1)/2))^2;
min_valid_node_cluster_sz = 5;% pvalue < 0.05 (0.5^5???)
if isfield(movieInfo, 'arc_avg_mid_std') && g.useOldArcProps
    arc_avg_mid_std = movieInfo.arc_avg_mid_std;
else
    arc_avg_mid_std = inf(length(movieInfo.xCoord), 4);
end
for i=1:numel(movieInfo.tracks)
    if length(movieInfo.tracks{i})>=g.trackLength4var
        % only long tracks considered
        costs = arc_cost_in_track(movieInfo, i, false, g.k);
        arc_avg_mid_std(movieInfo.tracks{i}, 1) = mean(costs);
        arc_avg_mid_std(movieInfo.tracks{i}, 2) = median(costs);
        arc_avg_mid_std(movieInfo.tracks{i}, 3) = std(costs);
        
        % if in the track, there are consistent low-cost linkages, label
        % them as stable nodes. Such nodes should be correctly segmented.
        f = movieInfo.frames(movieInfo.tracks{i});
        f_diff = f(2:end) - f(1:end-1);
        [l, n] = bwlabel(costs<=maxcost & f_diff==1); % should we only consider adjacent frames?
        for j=1:n
            stable_nodes = find(l==j);
            if length(stable_nodes) >= min_valid_node_cluster_sz
                stable_nodes = unique(cat(1,stable_nodes,stable_nodes+1));
                old_label1 = arc_avg_mid_std(movieInfo.tracks{i}(stable_nodes(1)), 4);
                old_label2 = arc_avg_mid_std(movieInfo.tracks{i}(stable_nodes(end)), 4);
                
                arc_avg_mid_std(movieInfo.tracks{i}(stable_nodes), 4) = 2;
                
                if isinf(old_label1) || old_label == 1% if is 2 or 3, set as 2
                    arc_avg_mid_std(movieInfo.tracks{i}(stable_nodes(1)), 4) = 1;
                end
                if isinf(old_label2) || old_label == 3
                    arc_avg_mid_std(movieInfo.tracks{i}(stable_nodes(end)), 4) = 3;
                end
                
            end
        end
    end
end
movieInfo.arc_avg_mid_std = arc_avg_mid_std;

