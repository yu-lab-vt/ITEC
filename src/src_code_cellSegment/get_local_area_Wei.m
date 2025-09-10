function comMaps = get_local_area_Wei(vid,idMap,reg_id,eig3d, eig2d, yxz, shift)

%% This function is to crop the information we need that only contains the targeted region(s)
% INPUT:
%        vid:the input 3D data
%        idMap:the label map of detected seed
%        reg_id:the id we focus on
%        eig3d:the 3d curvature
%        eig2d:the 2D curvature
%        yxz: the foreground detected by curvature
%        shift:the size of area we want
% OUTPUT:
%        comMaps:the local targeted regions containing all information

comMaps = [];
comMaps.idComp = crop3D(idMap, yxz, shift);
[comMaps.vidComp,comMaps.linerInd, ~, ~] = crop3D(vid, yxz, shift);
if isnan(reg_id)
    return;
end
comMaps.regComp = (comMaps.idComp == reg_id);

%% build 3d/2d principal curveture score map
eig3dComp = crop3D(eig3d, yxz, shift);
eig2dComp = crop3D(eig2d, yxz, shift);

comMaps.score3dMap = eig3dComp;     
comMaps.score3dMap(isnan(comMaps.score3dMap)) = 0;
comMaps.score2dMap = eig2dComp;     
comMaps.score2dMap(isnan(comMaps.score2dMap)) = 0;

comMaps.newIdComp = comMaps.regComp;
end


