function detect_divPair = candidate_divDetection(movieInfo, paras)

%% This function is to detect division
% INPUT:
%      movieInfo: tracking results
%      paras:parameters of division
% OUTPUT:
%      detect_divPair: division results

%% step1 estimate the motion variance of cells
movieInfo = brown_var_estimation(movieInfo,paras); 
%% step2 find candidateChild
% rule1 Distance level: be close enough to candidateParent(5-nearest)
% rule2 Trajectories level: head of tracks
% Rule-based test
head_list = find(cellfun(@length, movieInfo.parents)==0 & cellfun(@length, movieInfo.kids)~=0 ...
                & movieInfo.frames ~= min(movieInfo.frames));
fprintf('Division detection step 1: candidate filtering...\n');
cell_num = length(head_list);
div_num = 0;
child_pair = nan(cell_num,4);
for ii = 1:length(head_list)
    if mod(ii,1000) == 0
        fprintf('%d / %d\n', ii, cell_num);     
    end
    cell_id = head_list(ii);
    nei = findNeighbor(movieInfo, cell_id, paras, -1); 
    %nei_nochild = nei(cellfun(@length, movieInfo.kids(nei))==0);
    %nei = nei(cellfun(@length, movieInfo.kids(nei))~=0);
    child_pair_tem = nan(length(nei),4);
    for jj = 1:length(nei)
        child_pair_tem(jj,1) = cell_id;
        % case1: already have a kid
        if ~isempty(movieInfo.kids{nei(jj)})
            child_pair_tem(jj,2) = movieInfo.kids{nei(jj)};
        % case2: have no kid
        else 
            nei_child = findNeighbor(movieInfo, nei(jj), paras, 1);
            nei_child_head = setdiff(intersect(nei_child,head_list),cell_id);
            if ~isempty(nei_child_head)
                child_pair_tem(jj,2) = nei_child_head(1);
            else
                continue;
            end
        end
        [child_pair_tem(jj,3),child_pair_tem(jj,4)] = rule_based_test(movieInfo, nei(jj), ...
                    child_pair_tem(jj,1:2), paras);
    end
    id_tem = find(child_pair_tem(:,3) == 1);
    if isempty(id_tem)
        continue;
    else
        div_num = div_num + 1;
        if length(id_tem) > 1
            [~,id_tem] = min(child_pair_tem(:,4));
        end
        child_pair(div_num,:) = [nei(id_tem),cell_id,child_pair_tem(id_tem,2),child_pair_tem(id_tem,4)];
    end
end
child_pair = child_pair(1:div_num,:);

%% step3 Remove Conflicts:
% choose the pair with smaller test score  
fprintf('Division detection step 2: remove conflicts...\n');
child_pair = sortrows(child_pair, [1,4]);  
[~, idx] = unique(child_pair(:,1), 'first');   
detect_divPair = child_pair(idx, :); 
detect_divPair(:, [2 3]) = detect_divPair(:, [3 2]);
end