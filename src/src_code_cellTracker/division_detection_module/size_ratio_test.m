function size_ratio_flag = size_ratio_test(movieInfo, parent_id, ...
                                    children_pair, paras) 
%% This function is to determine size constraints
% INPUT:
%     movieInfo:results of tracking
%     parent_id:id of parent
%     children_pair:id of children
%     paras:parameters of division
% OUTPUT:
%     size_ratio_flag:flag for size constraints

child2parent_ratio = paras.child2parent_ratio;
size_ratio = paras.size_ratio;

% Rule1 children should be smaller than their parents
voxIdx_lengths = cellfun(@length, {movieInfo.voxIdx{children_pair}});
size_ratio_flag1 = all(voxIdx_lengths <= length(movieInfo.voxIdx{parent_id}) * child2parent_ratio);
% Rule2 The size difference between the two children should not be too significant
size_ratio_flag2 = voxIdx_lengths(1) <= voxIdx_lengths(2) * size_ratio ...
                   & voxIdx_lengths(1) >= voxIdx_lengths(2) / size_ratio;
size_ratio_flag = size_ratio_flag1 & size_ratio_flag2;
end