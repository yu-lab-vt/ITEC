function labelwrite(data, label, path)

%% This function is to write the label
% INPUT:
%     data:input 3D data
%     label:input label of detected cells
%     path:storage path
outIm = imdisplayWithMapColor4D(data,label);
write4dTiffRGB(uint8(outIm),[path '.tif']);
end