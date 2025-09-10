function [out_c1, out_c2, flag1, flag2] = xorCells(in_c1, in_c2, nodes_inconsistent)
% remove the rows in two Cell vectors with overlapped element
% NOTE: in in_c2, only 2nd and 3rd columns are valid

if nargin == 2
    nodes_inconsistent = [];
end
flag1 = true(numel(in_c1),1);
flag2 = true(numel(in_c2), 1);
if isempty(in_c1) || isempty(in_c2)
    out_c1=in_c1;
    out_c2=in_c2;
    return;
end

vec_c1 = cat(2, in_c1{:});
%vec_c1 = vec_c1(:);
nodes2split_cell  = cellfun(@(x) x(2:end), in_c2, 'UniformOutput', false);
vec_c2 = cat(2, nodes2split_cell{:});
% vec_c2 = cat(1, in_c2{:});
% vec_c2 = vec_c2(:,2:3); % in in_c2, only 2nd and 3rd columns are valid
%vec_c2 = vec_c2(:);
if isempty(intersect(vec_c1, vec_c2))
    out_c1=in_c1;
    out_c2=in_c2;
    return;
end
%flag1 = true(numel(in_c1), 1);
if ~isempty(nodes_inconsistent) 
    nodes_inconsistent = sort(nodes_inconsistent, 2); % each row indicate the nodes to merge
end
for i=1:numel(in_c1) % in_c1 is sorted already
    if ~isempty(intersect(in_c1{i},vec_c2)) 
        if ~isempty(nodes_inconsistent) 
            flag1(i) = false;
            for j=1:size(nodes_inconsistent,1)
                tmp = intersect(nodes_inconsistent(j,:), in_c1{i});
                if length(tmp) == length(in_c1{i}) && length(tmp) == ...
                        length(nodes_inconsistent(j,:))
                    flag1(i) = true;
                    break;
                end
            end
        else
            flag1(i) = false;
        end
    end
end
out_c1=in_c1(flag1);

%flag2 = true(numel(in_c2), 1);
for i=1:numel(in_c2)
    if ~isempty(intersect(in_c2{i}(2:end),vec_c1))
        flag2(i) = false;
    end
end
out_c2=in_c2(flag2);
