function [paras, paras_instSeg, paras_tracking] = set_paras(filepath)

%% This function is to load all parameters for tracking from csv format
% INPUT:
%    filepath：path of csv
% OUTPUT:
%    paras:general paras
%    paras_instSeg:paras for segmentation
%    paras_tracking:paras for tracking

    % get parameters from csv
    fid = fopen(filepath,'r');
    if fid == -1
        error('The parameter file does not exist!');
    end
    fgetl(fid); 
    fgetl(fid);
    data = textscan(fid, '%s %s %s %s %s %s', 'Delimiter', ',');
    fclose(fid);

    general_param_names = data{1};
    general_param_values = data{2};
    instSeg_param_names = data{3};
    instSeg_param_values = data{4};
    tracking_param_names = data{5};
    tracking_param_values = data{6};
    general_param_names = general_param_names(~cellfun(@isempty, general_param_names));
    general_param_values = general_param_values(~cellfun(@isempty, general_param_names));
    instSeg_param_names = instSeg_param_names(~cellfun(@isempty, instSeg_param_names));
    instSeg_param_values = instSeg_param_values(~cellfun(@isempty, instSeg_param_names));
    tracking_param_names = tracking_param_names(~cellfun(@isempty, tracking_param_names));
    tracking_param_values = tracking_param_values(~cellfun(@isempty, tracking_param_names));

    paras = initial_paras();
    paras = val_convert(general_param_names,general_param_values,paras);
    if ~isempty(paras.start_tm) & ~isempty(paras.end_tm)
        paras.tps_to_process = paras.start_tm:paras.end_tm;
    end
    if isempty(paras.data_path) 
        paras.data_path = '../data';  
    end
    if isempty(paras.result_path)
        paras.result_path = '../result';  
    end
    if paras.z_resolution > 1
        paras.shift(3) = round(paras.shift(3)/(min(floor(paras.z_resolution),4)));
    end
    if paras.z_resolution <= 2
        paras.filter_sigma = [paras.filter_sigma,paras.filter_sigma,paras.filter_sigma/paras.z_resolution];
    else
        paras.filter_sigma = [paras.filter_sigma,paras.filter_sigma,0];
    end
    paras.tmp_path = fullfile(paras.result_path,'tmp');
    paras_instSeg = initial_paras_instSeg(paras);
    paras_instSeg = val_convert(instSeg_param_names,instSeg_param_values,paras_instSeg);

    paras_tracking = initial_paras_tracking(paras); 
    paras_tracking = val_convert(tracking_param_names,tracking_param_values,paras_tracking);

    paras = merge_vector_fields(paras);
    paras_instSeg = merge_vector_fields(paras_instSeg);
    paras_tracking = merge_vector_fields(paras_tracking);
end

function paras = val_convert(paras_names,paras_values,paras)
for i = 1:length(paras_names)
    name = paras_names{i};
    val = paras_values{i};
    if contains(val, ':')
        parts = strsplit(val, ':');
        if length(parts) == 2
            num1 = str2double(parts{1});
            num2 = str2double(parts{2});
            if ~isnan(num1) && ~isnan(num2)
                val_use = num1:num2;
            else
                val_use = val;
            end
        else
            val_use = val;
        end
    elseif contains(val,';')
        val = erase(val, '"'); 
        parts = strsplit(val, ';');
        val_use = str2double(parts);
    else
        num_val = str2double(val);
        if ~isnan(num_val)
            val_use = num_val;
        else
            if strcmpi(val, 'true')
                val_use = true;
            elseif strcmpi(val, 'false')
                val_use = false;
            else
                val_use = val; 
            end
        end
    end
    paras = assign_field(paras, name, val_use);
end
end


function s = assign_field(s, name, val)
    expr = '(.*)_(\d+)$';
    tokens = regexp(name, expr, 'tokens');
    if ~isempty(tokens)
        base_name = tokens{1}{1};
        idx = str2double(tokens{1}{2});
        if isfield(s, [base_name '_vec'])
            vec_struct = s.([base_name '_vec']);
        else
            vec_struct = struct();
        end
        vec_struct.(['f' sprintf('%03d', idx)]) = val; 
        s.([base_name '_vec']) = vec_struct;
    else
        s.(name) = val;
    end
end

function s = merge_vector_fields(s)
    f = fieldnames(s);
    for i=1:length(f)
        if endsWith(f{i},'_vec')
            base_name = extractBefore(f{i},'_vec');
            vec_struct = s.(f{i});
            keys = fieldnames(vec_struct);
            nums = str2double(extractAfter(keys, 1)); 
            [~, idx_sort] = sort(nums);
            sorted_keys = keys(idx_sort);

            vec = zeros(1,length(sorted_keys));
            for j=1:length(sorted_keys)
                vec(j) = vec_struct.(sorted_keys{j});
            end
            s.(base_name) = vec;
            s = rmfield(s,f{i});
        end
    end
end

