function movieInfo = relinkJumpOveredCell(movieInfo, g)

% check jump, if there a->c, but a->b < obzCost, b->c < obzCost, link them
% NOTE: this is only applied to one to one linking

for i=1:length(movieInfo.xCoord)
    if ~isempty(movieInfo.kids{i})
        f_k = unique(movieInfo.frames(movieInfo.kids{i}));
        if f_k - movieInfo.frames(i) == 1 || length(movieInfo.kids{i}) ~= 1
            % not jump or there are multiple kids (too complicated)
            continue;
        end
        % there is a jump
        p_n = movieInfo.nei{i};
        p_n_pEmpty = cellfun(@isempty, movieInfo.parents(p_n));
        p_Cij = movieInfo.Cij{i};
        k_pN = movieInfo.preNei{movieInfo.kids{i}}; % only one kid
        k_pN_kEmpty = cellfun(@isempty, movieInfo.kids(k_pN));
        k_Cji = movieInfo.Cji{movieInfo.kids{i}}; % only one kid
        
        can_p = p_n(movieInfo.frames(p_n)==movieInfo.frames(i)+1 & ...
            p_Cij < abs(g.observationCost) & p_n_pEmpty);
        if ~isempty(can_p)
            %test_Cji = k_Cji(movieInfo.frames(k_pN)==f_k-1);
            can_k = k_pN(movieInfo.frames(k_pN)==f_k-1 & ...
                k_Cji < abs(g.observationCost) & k_pN_kEmpty);
        else
            continue;
        end
        if ~isempty(can_k)
            % there is a potential missed linking
            if f_k-1 == movieInfo.frames(i)+1
                test_id = intersect(can_k,can_p);
                if isempty(test_id)
                    continue;
                elseif length(test_id) > 1
                    c_all = inf(length(test_id), 1);
                    for j=1:length(test_id)
                        c_all(j) = p_Cij(p_n==test_id(j));
                        c_all(j) = c_all(j) + ...
                            k_Cji(k_pN==test_id(j));
                    end
                    [~, od] = min(c_all);
                    test_id = test_id(od);
                end
                cur_track_id = movieInfo.particle2track(i,1);
                pre_loc = movieInfo.particle2track(i,2);
                post_loc = movieInfo.particle2track(movieInfo.kids{i},2);
                cur_track = movieInfo.tracks{cur_track_id};
                cur_track = cat(1, cur_track(1:pre_loc), ...
                    test_id, cur_track(post_loc:end));
                movieInfo.tracks{cur_track_id} = cur_track;
                
                movieInfo.kids{test_id} = movieInfo.kids{i};
                movieInfo.parents{test_id} = i;
                movieInfo.parents{movieInfo.kids{i}} = test_id;
                movieInfo.kids{i} = test_id;
                
            else % there should be a tiny track by jumped
                k_track = movieInfo.particle2track(can_k,1);
                p_track = movieInfo.particle2track(can_p,1);
                track_id = intersect(k_track,p_track);
                track_id = unique(track_id(~isnan(track_id)));
                if isempty(track_id)
                    continue;
                elseif length(track_id) > 1
                    c_all = inf(length(track_id), 1);
                    for j=1:length(track_id)
                        c_all(j) = p_Cij(p_n==movieInfo.tracks{track_id(j)}(1));
                        c_all(j) = c_all(j) + ...
                            k_Cji(k_pN==movieInfo.tracks{track_id(j)}(end));
                    end
                    [~, od] = min(c_all);
                    track_id = track_id(od);
                end
                cur_track_id = movieInfo.particle2track(i,1);
                pre_loc = movieInfo.particle2track(i,2);
                post_loc = movieInfo.particle2track(movieInfo.kids{i},2);
                cur_track = movieInfo.tracks{cur_track_id};
                cur_track = cat(1, cur_track(1:pre_loc), ...
                    movieInfo.tracks{track_id}, cur_track(post_loc:end));
                movieInfo.tracks{cur_track_id} = cur_track;
                
                th = movieInfo.tracks{track_id}(1);
                te = movieInfo.tracks{track_id}(end);
                movieInfo.kids{te} = movieInfo.kids{i};
                movieInfo.parents{th} = i;
                movieInfo.parents{movieInfo.kids{i}} = te;
                movieInfo.kids{i} = th;
                
                movieInfo.tracks{track_id} = [];
            end
            % particle2track
            movieInfo.particle2track(cur_track,1) = cur_track_id;
            movieInfo.particle2track(cur_track,2) = 1:length(cur_track);
        end
    end
end
end