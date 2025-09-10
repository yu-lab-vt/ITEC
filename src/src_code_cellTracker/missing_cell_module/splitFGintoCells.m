function comMaps = splitFGintoCells(fg, fgboundary, seedRegionIn, comMaps, append_id, q)
% give fg from order statistics, we test if the fg contains several seeds
% and if so, split fg based on the seeds

if ~isfield(q, 'growSeedinTracking')
    q.growSeedinTracking = false;
end
% fg contains other ids (append_id) or the seed region itself contains
% multiple ids
if ~isnan(append_id) || length(unique(comMaps.idComp(seedRegionIn>0)))>1
    % there is multiple seeds
    if ~q.growSeedinTracking
        fgIn = fg;
        % 2d first?
        newLabel = regionGrow(seedRegionIn, ...
            comMaps.score2dMap,...
            fgIn, q.growConnectInTest, ...
            q.cost_design, true);
        newLabel = regionGrow(newLabel, ...
            comMaps.score2dMap+comMaps.score3dMap,...
            fgIn, q.growConnectInRefine, ...
            q.cost_design, false);
        
        newLabel(~fg) = 0;
        % here for extra voxels
        if ~isempty(find(fg & (newLabel==0), 1))
            newLabel = extraVoxReassign(newLabel, fg);
        end
        if ~isnan(append_id)
            newLabel(newLabel == append_id) = 0;
        end
        fg = newLabel>0;
    else
        % Grow all regions again, not only current one, so we can update
        % all the regions.
        % We should always grow all regions related to fg, otherwise, we
        % cannot get an accurate neighboring relationships. Thus the we
        % will only run the 'else' part in the following judgement.
        if false %~q.updateCellsAdjMissingCell 
            if ~isnan(append_id)
                other_id_map = seedRegionIn == append_id;
                seedRegionIn(other_id_map) = 0;
            end
            seedRegionIn(seedRegionIn>0) = comMaps.idComp(seedRegionIn>0);
            [seedRegion, reg_cnt, id_map] = rearrange_id(seedRegionIn);
            append_bndMap = fgboundary & fg & seedRegion==0;
            if ~isnan(append_id)
                append_bndMap = append_bndMap | other_id_map;
            end
        else
            cur_id_map = comMaps.idComp;
            cur_id_map(~fg) = 0;
            [seedRegion, reg_cnt, id_map] = rearrange_id(cur_id_map);
            append_bndMap = fgboundary & fg & seedRegion==0;
        end
        if reg_cnt <= 1 && isempty(find(append_bndMap,1))
            %comMaps.idComp = zeros(size(fg));
            comMaps.idComp(comMaps.idComp == id_map(1)) = 0;
            comMaps.idComp(fg) = id_map(1); % reg_cnt cannot be 0
        else
            if ~isempty(append_bndMap)
                seedRegion(append_bndMap) = reg_cnt + 1;
            end

            fgIn = fg;
            if max(seedRegion(:)) == 1
                keyboard;
            end
            newLabel = regionGrow(seedRegion, ...
                comMaps.score2dMap,...
                fgIn, q.growConnectInTest, ...
                q.cost_design, true);
            if max(newLabel(:)) == 1
                keyboard;
            end
            newLabel = regionGrow(newLabel, ...
                comMaps.score2dMap+comMaps.score3dMap,...
                fgIn, q.growConnectInRefine, ...
                q.cost_design, false);

            newLabel(~fg) = 0; % no need?
            % here for extra voxels
            if ~isempty(find(fg & (newLabel==0), 1))
                newLabel = extraVoxReassign(newLabel, fg);
            end
            if ~isempty(append_bndMap)
                newLabel(newLabel == reg_cnt + 1) = 0;
            end

            % map back all ids and renew idComp
            %comMaps.idComp = zeros(size(newLabel));
            comMaps.idComp(fg) = 0; % outside fg should be no-change
            for i=1:reg_cnt
                od = find(id_map(:,2)==i,1);
                comMaps.idComp(newLabel == i) = id_map(od,1);
            end
            % comMaps.regComp&fg represents the target region we want
            target_id = newLabel(comMaps.regComp & fg); 
            target_id = min(target_id(target_id>0)); % usually target_id 
            % should only contains one id; but there is a quite rare case
            % that we will seed target_id contains multiple ids, which the
            % minimum one is the target id (but others will also be updated).
            fg = newLabel == target_id;
        end
    end
elseif q.growSeedinTracking
    % for region detection in tracking, we only needs regions in foreground
    % so we remove other regions in background
    target_id = comMaps.idComp(find(comMaps.idComp>0 & fg,1));
    if ~isempty(target_id)
        %comMaps.idComp = zeros(size(fg));
        comMaps.idComp(comMaps.idComp == target_id) = 0;
        comMaps.idComp(fg) = target_id;
    else
        warning('Possible bug! check first!');
        comMaps.idComp(comMaps.idComp == target_id) = 0; % remove the seed maps
        fg = false(size(comMaps.idComp));
    end
end
comMaps.regComp = fg; % save the detected foreground
comMaps.fmapComp = fg;
end