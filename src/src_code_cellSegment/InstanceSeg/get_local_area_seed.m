function comMaps = get_local_area_seed(candidate, shift)

%% This function is to crop the info we need that only contains the targeted region(s)
% INPUT:
%        candidate:the seed region we focus on
%        shift:the size of area we want
% OUTPUT:
%        comMaps:the local targeted regions containing all information

comMaps = [];
yxz = find(candidate);
[comMaps.idComp,comMaps.linerInd] = crop3D(candidate, yxz, shift);
end