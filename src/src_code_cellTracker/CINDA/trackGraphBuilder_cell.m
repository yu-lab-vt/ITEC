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
    transition_arcs = zeros(1e8,3);
    % transition linking
    k_dat = 0;
    for i=1:vNum
        f2 = movieInfo.nei{i};
        for j = 1:length(f2)
            k_dat = k_dat+1;
            transition_arcs(k_dat,:) = [i f2(j) movieInfo.Cij{i}(j)];
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