function phi_current = imresize4d(phi_current, scale, method)

%% This function is to transform to 4d data if table
% resize 4d data
% gpu not supported
% INPUT:
%      phi_current:motion vector
%      scale:scale size
%      method:method flag
% OUTPUT:
%      phi_current:motion vector

flag = 0;
if isgpuarray(phi_current)
    isgpu = 1;
    phi_current = gather(phi_current);
else
    isgpu = 0;
end
if ismatrix(phi_current)       % if table
    % change to [3 []]
    if size(phi_current,1) == 3
        flag = 1;
    elseif size(phi_current, 2) == 3
        flag = 1;
        phi_current = phi_current';
    end
    if flag
        batch_dim = round(size(phi_current,2)^(1/3));
        if batch_dim^3 ~= size(phi_current,2)
            error('Incorrect number of elements.');
        end
        if isscalar(scale)
            scale = [batch_dim batch_dim batch_dim] * scale;
        end
        phi_current_temp = phi_current';
        phi_current = zeros([scale 3]);
        if size(phi_current_temp,1) == 1
            phi_current(:,:,:,1) = phi_current_temp(:,1);
            phi_current(:,:,:,2) = phi_current_temp(:,2);
            phi_current(:,:,:,3) = phi_current_temp(:,3);
        else
            phi_current(:,:,:,1) = imresize3(reshape(phi_current_temp(:,1), batch_dim, batch_dim, batch_dim), scale, method);
            phi_current(:,:,:,2) = imresize3(reshape(phi_current_temp(:,2), batch_dim, batch_dim, batch_dim), scale, method);
            phi_current(:,:,:,3) = imresize3(reshape(phi_current_temp(:,3), batch_dim, batch_dim, batch_dim), scale, method);
        end
    end
elseif  ndims(phi_current) == 4
    if size(phi_current,4) == 3
        flag = 1;
        if isscalar(scale)
            scale = size(phi_current(:,:,:,1)) * scale;
        end
        phi_current_temp = phi_current;
        phi_current = zeros([scale 3]);
        phi_current(:,:,:,1) = imresize3(phi_current_temp(:,:,:,1), scale, method);
        phi_current(:,:,:,2) = imresize3(phi_current_temp(:,:,:,2), scale, method);
        phi_current(:,:,:,3) = imresize3(phi_current_temp(:,:,:,3), scale, method);
    end
end
if isgpu
    phi_current = gpuArray(phi_current);
end
if flag == 0
    warning('Incorrect input. No operations.');
end
    
end