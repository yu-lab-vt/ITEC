function frame_shift = getNonRigidDrift(curVox, neiVox, curFrame, neiFrame, drift, driftInfo)
%% calculate the drift prediction based on non-rigid registration info
% INPUT: 
%     curVox ------ m*3 current cell voxels (yxz format)
%     neiVox ------ n*3 neighbor cell voxels
%     curFrame ---- current cell frames
%     neiFrame ---- nextCell frames
%     drift ------- movieInfo.drift
%     driftInfo --- g.driftInfo
% OUTPUT:
%     frame_shift - prediction based on the later frame

    % input check
    if size(curVox, 2) ~= 3 || size(neiVox, 2) ~= 3
        error('Incorrect voxel input.');
    end
    if curFrame == neiFrame
        error('Incorrect frame input.');
    end
    curVox = mean(curVox, 1);
    neiVox = mean(neiVox, 1);
    if curFrame > neiFrame
        % make current cell is former
        [curVox, neiVox] = deal(neiVox, curVox);
        [curFrame, neiFrame] = deal(neiFrame, curFrame);
        swap_flag = true;
    else
        swap_flag = false;
    end
    
    % predict drift
    tempVox = neiVox;
    for tt = neiFrame-1:-1:curFrame
        y_bias = interp3(driftInfo.y_batch, driftInfo.x_batch, driftInfo.z_batch,...
            drift.y_grid{tt}, tempVox(1), tempVox(2), tempVox(3), 'linear',0);
        x_bias = interp3(driftInfo.y_batch, driftInfo.x_batch, driftInfo.z_batch,...
            drift.x_grid{tt}, tempVox(1), tempVox(2), tempVox(3), 'linear',0);
        z_bias = interp3(driftInfo.y_batch, driftInfo.x_batch, driftInfo.z_batch,...
            drift.z_grid{tt}, tempVox(1), tempVox(2), tempVox(3), 'linear',0);
        tempVox = tempVox + [y_bias x_bias z_bias];
    end
    frame_shift = neiVox - tempVox;
    
    if swap_flag
        frame_shift = -frame_shift;
    end

end