function tifwrite(outLabel, ImName)

%% This function is to write the color image into tif format
% INPUT:
%      outLabel:color image
%      ImName:file name
% OUTPUT:
% the output will be stored in ImName path

if size(outLabel,4)==1 
    if size(outLabel,3) ~= 3
        imwrite(outLabel(:,:,1),[ImName,'.tif']);
        for i = 2:size(outLabel,3)
            imwrite(outLabel(:,:,i),[ImName,'.tif'],'WriteMode','append');
        end
    else
        imwrite(outLabel,[ImName,'.tif']);
    end
else    
    imwrite(outLabel(:,:,:,1),[ImName,'.tif']);
    for i = 2:size(outLabel,4)
        imwrite(outLabel(:,:,:,i),[ImName,'.tif'],'WriteMode','append');
    end
end
end