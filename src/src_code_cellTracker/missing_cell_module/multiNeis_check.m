function adj_pk_vec = multiNeis_check(parent_kid_vec, append_idx, ...
    movieInfo, refine_res)
% check if the newly detected cell indeed corresponds to two cells in
% previous or latter frame
% we only check the case of two cells

f = movieInfo.frames(parent_kid_vec);

real_ids = refine_res{f(1)}(append_idx);
out_freq = frequency_cnt(real_ids(real_ids>0));

adj_pk_vec = [];
if size(out_freq, 1) < 2
    return;
end
p_real_id = refine_res{f(1)}(movieInfo.voxIdx{parent_kid_vec(1)}(1));
out_freq(out_freq(:,1)==p_real_id,:) = [];

[~, od] = max(out_freq(:,2));
potential_adj_p = out_freq(od, 1);
if potential_adj_p<=movieInfo.n_perframe(f(1))
    potential_adj_p = potential_adj_p + sum(movieInfo.n_perframe(1:f(1)-1));
end

potential_adj_k = movieInfo.kids{potential_adj_p};

if length(potential_adj_k) ~= 1
    return;
end

if movieInfo.frames(potential_adj_k) ~= f(2)
    return;
end

adj_pk_vec = [potential_adj_p, potential_adj_k];
