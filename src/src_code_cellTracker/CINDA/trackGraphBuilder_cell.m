function [orgG, g, dat_in] = trackGraphBuilder_cell(movieInfo, g)

% build graph for tracking
if ~isfield(g, 'cycle_track')
    circulation_graph = false;
else
    if g.cycle_track == false
        circulation_graph = false;
    else
        circulation_graph = true;
    end
end
if circulation_graph
    orgG = [];
    vNum = length(movieInfo.Ci);%g.particleNum;
    g.n_nodes = 2*vNum+1; % number of nodes in the graph
    dat_in = cell(2,1); %  detection matrix andtransition matrix
    detection_arcs = cat(2, (1:vNum)', g.c_en*ones(vNum,1), ...
        g.c_en*ones(vNum,1), movieInfo.Ci);
    % The fourth column marks an association that is manually locked.
    transition_arcs = zeros(1e8,4);
    % transition linking. A lock cost dominates all finite graph costs;
    % conflicts are removed below and mccTracker verifies the final result.
    lock_cost = sum(abs(movieInfo.Ci(isfinite(movieInfo.Ci)))) + 1;
    for cost_i = 1:numel(movieInfo.Cij)
        values = movieInfo.Cij{cost_i};
        lock_cost = lock_cost + sum(abs(values(isfinite(values))));
    end
    lock_cost = 10 * max(lock_cost, 1);
    k_dat = 0;
    for i=1:vNum
        f2 = movieInfo.nei{i};
        for j = 1:length(f2)
            child = f2(j);
            is_locked = false;
            is_allowed = true;
            if isfield(movieInfo, 'lockNoParent') && movieInfo.lockNoParent(child)
                is_allowed = false;
            elseif isfield(movieInfo, 'lockParent') && ~isnan(movieInfo.lockParent(child))
                is_allowed = movieInfo.lockParent(child) == i;
                is_locked = is_allowed;
            end
            if is_allowed
                k_dat = k_dat+1;
                edge_cost = movieInfo.Cij{i}(j);
                if is_locked
                    edge_cost = -lock_cost;
                end
                transition_arcs(k_dat,:) = [i child edge_cost is_locked];
            end
        end
    end
    transition_arcs = transition_arcs(1:k_dat,:);
    
    dat_in{1} = detection_arcs;
    dat_in{2} = transition_arcs;
else
    vNum = g.particleNum;
    g.n_nodes = 2*vNum+2; %% number of nodes in the graph
    dat_in = zeros(1e8,3); %% each row represents an edge from node in column 1 to node in column 2 with cost in column 3.
    
    % source/sink linking and observation linking
    k_dat = 0;
    for i = 1:vNum
        k_dat = k_dat+3;
        dat_in(k_dat-2,:) = [1      2*i     g.c_en];
        dat_in(k_dat-1,:) = [2*i    2*i+1   movieInfo.Ci(i) ];
        dat_in(k_dat,:)   = [2*i+1  g.n_nodes g.c_ex];
    end
    
    % transition linking
    for i=1:vNum
        f2 = movieInfo.nei{i};
        for j = 1:length(f2)
            k_dat = k_dat+1;
            dat_in(k_dat,:) = [2*i+1 2*f2(j) movieInfo.Cij{i}(j)];
        end
    end
    dat_in = dat_in(1:k_dat,:);
    if (k_dat>1e8)
        error('preSet a larger vector for graph builder!');
    end
    
    g.excess_node = [1 g.n_nodes];  % push flow in the first node and collect it in the last node.
    % k shortest paths from residual network
    orgG = digraph(dat_in(:,1),dat_in(:,2),dat_in(:, 3)); % head, tail weight
end
fprintf('finish graph building!\n');

end