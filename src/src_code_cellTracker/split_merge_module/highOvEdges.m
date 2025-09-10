function [dat_in_ap, movieInfo] = highOvEdges(movieInfo, g)
% add multi-to-one or one-to-multi choices; for >1 regions that has high 
% overlapping ratios with one pre- or post- neighbor, add links for such
% region to src or sink such that one region can incident with >1 regions
% INPUT:
% movieInfo: info about all the detections and tracks
% g.side_flag: 1 means only consider pre-side, 2: post side, 0: both side
% g.
% OUTPUT:
% dat_in_ap: a n by 3 matrix, indicating detection id, cost of linking to
% sink (pre-node, means allow two nodes linking to it), cost of src linking
% to it

% contact: ccwang@vt.edu, 03/06/2020
if ~isfield(g, 'side_flag')
    side_flag = 0;
else
    side_flag = g.side_flag;
end
% preNei = movieInfo.preNei;
% preOvSize = movieInfo.preOvSize;
% frames = movieInfo.frames;
edge_pre_cost = cell(numel(movieInfo.xCoord), 1);
nei_pre = cell(numel(movieInfo.xCoord), 1);
edge_post_cost = cell(numel(movieInfo.xCoord), 1);
nei_post = cell(numel(movieInfo.xCoord), 1);
for i=1:numel(movieInfo.xCoord)
    pre_valid_flag = true;
    post_valid_flag = true;
    if g.stableNodeTest % check tracklet's head and tail or isolated node
        if movieInfo.arc_avg_mid_std(i,4)==1
            post_valid_flag = false;
        elseif movieInfo.arc_avg_mid_std(i,4)==2
            pre_valid_flag = false;
            post_valid_flag = false;
        elseif movieInfo.arc_avg_mid_std(i,4)==3
            pre_valid_flag = false;
        end
    end
    if (side_flag==0 || side_flag == 1) && pre_valid_flag
        pre_nei = movieInfo.preNei{i};
        pre_ov = movieInfo.preOvSize{i};
        pre_fr = movieInfo.frames(pre_nei);
        if ~strcmp(g.splitMergeHandle, 'none') % does not consider jump
            validNei = pre_fr == (movieInfo.frames(i)-1);
            pre_fr = pre_fr(validNei);
            pre_ov = pre_ov(validNei);
            pre_nei = pre_nei(validNei);
        end
        [edge_cost_pre,ov_nei_pre] = append_edge_overlapping_based(pre_nei, pre_ov, ...
            pre_fr, i, movieInfo, false, g);
        edge_pre_cost{i} = edge_cost_pre;
        nei_pre{i} = ov_nei_pre;
    end
    if (side_flag==0 || side_flag == 2) && post_valid_flag
        post_nei = movieInfo.nei{i};
        post_ov = movieInfo.ovSize{i};
        post_fr = movieInfo.frames(post_nei);
        if ~strcmp(g.splitMergeHandle, 'none') % does not consider jump
            validNei = post_fr == (movieInfo.frames(i)+1);
            post_fr = post_fr(validNei);
            post_ov = post_ov(validNei);
            post_nei = post_nei(validNei);
        end
        [edge_cost_post,ov_nei_post] = append_edge_overlapping_based(post_nei, post_ov, ...
            post_fr, i, movieInfo, true, g);
        edge_post_cost{i} = edge_cost_post;
        nei_post{i} = ov_nei_post;
    end

end
ap_edge = 0;
dat_in_ap = zeros(numel(movieInfo.xCoord),3); % id, pre-sink cost, src-post cost, pre_neis, post_neis
for i=1:numel(movieInfo.xCoord)
    src2post_cost = nan;
    pre2sink_cost = nan;
    if ~isempty(edge_pre_cost{i}) % two-to-one
        % check first if anyone of the parents also forms one-to-two: a->b+c and a+d->b
        one2multi_parents = nei_pre{i}(~cellfun(@isempty, edge_post_cost(nei_pre{i})));
        parent_better = false;
        if ~isempty(one2multi_parents)
            % there indeed a or multiple parents forms one-to-two, for all
            % these regions, we keep the group with largest size
            cur_gp_sz = length(movieInfo.voxIdx{i}) ...
                + sum(cellfun(@length, movieInfo.voxIdx(nei_pre{i})));
            parent_gp_sz = zeros(length(one2multi_parents), 1);
            for j=1:length(one2multi_parents)
                cur_p = one2multi_parents(j);
                parent_gp_sz(j) = length(movieInfo.voxIdx{cur_p}) ...
                    + sum(cellfun(@length, movieInfo.voxIdx(nei_post{cur_p})));
            end
            max_gp_sz = max(cur_gp_sz, max(parent_gp_sz));
            for j=1:length(one2multi_parents)
                cur_p = one2multi_parents(j);
                if parent_gp_sz(j) == max_gp_sz
                    parent_better = true;
                    edge_pre_cost{i} = [];
                else
                    % remove invalid parents
                    edge_post_cost{cur_p} = [];
                    % remove invalid parents' kids other than i
                    nei_post{cur_p}(nei_post{cur_p} == i) = [];
                    edge_pre_cost(nei_post{cur_p}) = {[]};
                end
            end
        end
        if ~parent_better
            pre_nei = movieInfo.preNei{i};
            for j=1:length(edge_pre_cost{i})
                movieInfo.Cji{i}(pre_nei==nei_pre{i}(j)) = edge_pre_cost{i}(j);
                movieInfo.Cij{nei_pre{i}(j)}(movieInfo.nei{nei_pre{i}(j)}==i)...
                    = edge_pre_cost{i}(j);
            end
            pre2sink_cost = 0;
        end
    end
    
    if ~isempty(edge_post_cost{i}) % seems redundant???
        % check first if anyone of the kids also forms two-to-one: a->b+c and a+d->b
        multi2one_kids = nei_post{i}(~cellfun(@isempty, edge_pre_cost(nei_post{i})));
        kid_better = false;
        if ~isempty(multi2one_kids)
            % there indeed a or multiple kids forms two-to-one, for all
            % these regions, we keep the group with largest size
            cur_gp_sz = length(movieInfo.voxIdx{i}) ...
                + sum(cellfun(@length, movieInfo.voxIdx(nei_post{i})));
            kid_gp_sz = zeros(length(multi2one_kids), 1);
            for j=1:length(multi2one_kids)
                cur_k = multi2one_kids(j);
                kid_gp_sz(j) = length(movieInfo.voxIdx{cur_k}) ...
                    + sum(cellfun(@length, movieInfo.voxIdx(nei_pre{cur_k})));
            end
            max_gp_sz = max(cur_gp_sz, max(kid_gp_sz));
            for j=1:length(multi2one_kids)
                cur_k = multi2one_kids(j);
                if kid_gp_sz(j) == max_gp_sz
                    kid_better = true;
                    edge_post_cost{i} = [];
                else
                    % remove invalid kids
                    edge_pre_cost{cur_k} = [];
                    % remove invalid kids' parents other than i
                    nei_pre{cur_k}(nei_pre{cur_k} == i) = [];
                    edge_post_cost(nei_pre{cur_k}) = {[]};
                end
            end
        end
        if ~kid_better
            post_nei = movieInfo.nei{i};
            for j=1:length(edge_post_cost{i})
                movieInfo.Cij{i}(post_nei==nei_post{i}(j)) = edge_post_cost{i}(j);
                movieInfo.Cji{nei_post{i}(j)}(movieInfo.preNei{nei_post{i}(j)}==i)...
                    = edge_post_cost{i}(j);
            end
            src2post_cost = 0;
        end
    end
    if ~isnan(pre2sink_cost) || ~isnan(src2post_cost)
        ap_edge = ap_edge + 1;
        dat_in_ap(ap_edge,:) = [i, pre2sink_cost, src2post_cost];%, pre_neis, post_neis
    end
end
%dat_in_ap = cat(1, dat_in_ap{:});
dat_in_ap = dat_in_ap(1:ap_edge,:);
end