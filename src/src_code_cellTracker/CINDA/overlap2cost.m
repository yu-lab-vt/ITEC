function [cost, oc] = overlap2cost(ov_score, phat, jump_punish)

%% This function is to calulate the edge cost from the overlapping distance or ratio
% INPUT:
%     ov_score: initial overlapping ratio, or overlapping based distance
%     phat: gamma parameters
% OUTPUT:
%     cost: edge cost

if nargin < 3
    jump_punish = 1;
end
ov_score = ov_score(:);
jump_punish = jump_punish(:);

p_oc = gamcdf(ov_score, phat(1), phat(2),'upper');
oc = abs(norminv(p_oc.*jump_punish/2));
cost = oc.^2;
end