function [has_child_flag,div_score] = rule_based_test(movieInfo, parent_id, child_pair, paras)

%% This function is to determine size constraints
% INPUT:
%     movieInfo:results of tracking
%     parent_id:id of parent
%     child_pair:id of children
%     paras:parameters of division
% OUTPUT:
%     has_child_flag:flag for division test
%     div_score:score for division test

frame_flag = (movieInfo.frames(child_pair(2)) == movieInfo.frames(child_pair(1))) & ...
    (movieInfo.frames(parent_id) == movieInfo.frames(child_pair(1))-1);

%% find all detections and candidate divisions in movieInfo
% Rule1-Size level
% size_ratio_flag = size_ratio_test(movieInfo, parent_id, child_pair, paras); 
% Rule2-Motion level
div_score = motion_rule_test(movieInfo, parent_id, child_pair, paras);  
motion_flag = div_score <= paras.chi_thres;
has_child_flag = motion_flag & frame_flag;

end