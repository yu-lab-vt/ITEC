function movieInfo = applyLockedCorrections(movieInfo, q)
% Apply CSV parent edits as hard constraints for constrained re-tracking.
% Required columns: ID, parents, locked. A locked row fixes the incoming
% parent of ID. An empty/NaN parent fixes that detection as having no parent.

if ~isfield(q, 'correction_csv_path') || isempty(q.correction_csv_path)
    error('enable_locked_correction requires q.correction_csv_path.');
end
if ~isfile(q.correction_csv_path)
    error('Correction CSV not found: %s', q.correction_csv_path);
end

T = readtable(q.correction_csv_path);
names = T.Properties.VariableNames;
id_col = find(strcmpi(names, 'ID'), 1);
parent_col = find(strcmpi(names, 'parents'), 1);
lock_col = find(strcmpi(names, 'locked'), 1);
if isempty(id_col) || isempty(parent_col) || isempty(lock_col)
    error('Correction CSV must contain ID, parents, and locked columns.');
end

ids = double(T.(names{id_col}));
raw_lock = T.(names{lock_col});
if islogical(raw_lock)
    locked_rows = raw_lock;
elseif isnumeric(raw_lock)
    locked_rows = raw_lock ~= 0;
else
    locked_rows = ismember(lower(strtrim(string(raw_lock))), ["1", "true", "yes"]);
end
ids = ids(locked_rows);
raw_parents = T.(names{parent_col});
raw_parents = raw_parents(locked_rows,:);

n = numel(movieInfo.frames);
movieInfo.lockedDetection = false(n,1);
movieInfo.lockParent = nan(n,1);
movieInfo.lockNoParent = false(n,1);
if isempty(ids)
    warning('No rows with locked=true were found in the correction CSV.');
    return;
end
if any(~isfinite(ids) | ids ~= floor(ids) | ids < 1 | ids > n)
    error('Locked CSV IDs must be integer detection IDs in [1, %d].', n);
end
if numel(unique(ids)) ~= numel(ids)
    error('Each locked detection may occur only once in the correction CSV.');
end

locked_parents = nan(numel(ids),1);
for k = 1:numel(ids)
    parent_id = localParentId(raw_parents, k);
    child_id = ids(k);
    if isempty(parent_id)
        movieInfo.lockNoParent(child_id) = true;
        movieInfo.lockedDetection(child_id) = true;
        continue;
    end
    if ~isscalar(parent_id) || ~isfinite(parent_id) || parent_id ~= floor(parent_id) || ...
            parent_id < 1 || parent_id > n
        error('Locked parent for detection %d must be one valid scalar ID or empty.', child_id);
    end
    if movieInfo.frames(parent_id) >= movieInfo.frames(child_id)
        error('Locked parent %d must precede child %d in time.', parent_id, child_id);
    end
    if ~ismember(child_id, movieInfo.nei{parent_id})
        error(['Locked edge %d -> %d is not an eligible tracking candidate. ' ...
            'Increase the allowed jump range/distance before re-running.'], parent_id, child_id);
    end
    movieInfo.lockParent(child_id) = parent_id;
    movieInfo.lockedDetection([parent_id; child_id]) = true;
    locked_parents(k) = parent_id;
end

% Version 1 supports ordinary one-to-one parent associations only.
finite_parents = locked_parents(isfinite(locked_parents));
if numel(unique(finite_parents)) ~= numel(finite_parents)
    error('A parent cannot be locked to more than one child in correction mode.');
end
fprintf('Applied %d locked association constraints.\n', numel(ids));
end

function parent_id = localParentId(raw_parents, row)
parent_id = [];
if isnumeric(raw_parents)
    value = raw_parents(row);
    if ~isnan(value)
        parent_id = double(value);
    end
    return;
end
if iscell(raw_parents)
    value = raw_parents{row};
else
    value = raw_parents(row);
end
text = strtrim(string(value));
if strlength(text) == 0 || any(strcmpi(text, ["nan", "na", "none", "null"]))
    return;
end
parent_id = str2double(text);
if isnan(parent_id)
    error('Parent values must be numeric IDs or empty.');
end
end