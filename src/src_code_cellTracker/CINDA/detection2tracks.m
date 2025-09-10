function [tracks, particle2track, parents, kids, n_perframe] = detection2tracks(dets)

n_perframe = cellfun(@(x) size(x,1), dets);
tracks = cell(sum(n_perframe), 1);
track_cnt = 0;
particle2track = nan(sum(n_perframe),2);
parents = cell(sum(n_perframe),1);
kids = cell(sum(n_perframe),1);
for f=1:numel(dets)
    det_ids = (1:n_perframe(f))' + sum(n_perframe(1:f-1));
    % 4:parent, 5:frames, 6:track_id, 7: det_id
    for i=1:n_perframe(f)
        cur_pt = dets{f}(i,:);
        if isnan(cur_pt(4)) % new trajectory
            track_cnt = track_cnt + 1;
            tracks{track_cnt} = det_ids(i);
            particle2track(det_ids(i),:) = [track_cnt, 1];
        else % existing trajectory
            parent_pt = sum(n_perframe(1:f-2)) + cur_pt(4);
            tr_id = particle2track(parent_pt,1);
            tracks{tr_id} = cat(1, tracks{tr_id}, det_ids(i));
            particle2track(det_ids(i),:) = [tr_id, length(tracks{tr_id})];
            
            parents{det_ids(i)} = cat(1, parents{det_ids(i)}, parent_pt);
            kids{parent_pt} = cat(1, kids{parent_pt}, det_ids(i));
        end
    end

end
end