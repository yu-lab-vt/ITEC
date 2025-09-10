function square_stat = motion_rule_test(movieInfo, parent_id, ...
                                    children_pair, paras)  
%% This function is to determine motion constraints
% INPUT:
%     movieInfo:results of tracking
%     parent_id:id of parent
%     children_pair:id of children
%     paras:parameters of division
% OUTPUT:
%     square_stat:score for motion constraints

im_resolution = paras.im_resolution;
child1_id = children_pair(1);
child2_id = children_pair(2);
child_time = movieInfo.frames(child1_id);
frame_shift1 = getNonRigidDrift([0 0 0], movieInfo.orgCoord(child1_id,:),...
    child_time-1, child_time, movieInfo.drift, movieInfo.driftInfo);
frame_shift2 = getNonRigidDrift([0 0 0], movieInfo.orgCoord(child2_id,:),...
    child_time-1, child_time, movieInfo.drift, movieInfo.driftInfo);
coord1 = (movieInfo.orgCoord(child1_id,:) - frame_shift1 - ...
          movieInfo.orgCoord(parent_id,:)).*im_resolution;
coord2 = (movieInfo.orgCoord(child2_id,:) - frame_shift2 - ...
          movieInfo.orgCoord(parent_id,:)).*im_resolution;
r1 = ones(1,3)*(numel(movieInfo.voxIdx{child1_id})*3*prod(im_resolution)/4/pi)^(1/3);
r2 = ones(1,3)*(numel(movieInfo.voxIdx{child2_id})*3*prod(im_resolution)/4/pi)^(1/3);
normali = (coord1 + coord2)./sqrt(2*movieInfo.motion_var(child_time,:) + (1/3*r1).^2 + (1/3*r2).^2); 
%normali = (coord1 + coord2)./sqrt(2*movieInfo.motion_var(child_time,:)); 
square_stat = sum(normali.^2);
end