function save_paras(paras_basic, paras_seg, paras_tra, csv_path)

    data_cell = {};
    data_cell{1, 1} = 'parameters for ITEC';
    data_cell{2, 1} = 'General Parameters';
    data_cell{2, 3} = 'Segmentation Parameters';
    data_cell{2, 5} = 'Tracking Parameters';

    basic_fields = fieldnames(paras_basic);
    seg_fields = fieldnames(paras_seg);
    tra_fields = fieldnames(paras_tra);
    
    max_rows = max([length(basic_fields), length(seg_fields), length(tra_fields)]);
    start_row = 3;
    
    for i = 1:max_rows
        row_idx = start_row + i - 1;
        
        if i <= length(basic_fields)
            field = basic_fields{i};
            data_cell{row_idx, 1} = field;
            data_cell{row_idx, 2} = get_value_str(paras_basic.(field));
        end
        
        if i <= length(seg_fields)
            field = seg_fields{i};
            data_cell{row_idx, 3} = field;
            data_cell{row_idx, 4} = get_value_str(paras_seg.(field));
        end
        
        if i <= length(tra_fields)
            field = tra_fields{i};
            data_cell{row_idx, 5} = field;
            data_cell{row_idx, 6} = get_value_str(paras_tra.(field));
        end
    end
    
    writecell(data_cell, csv_path);
    
    fprintf('The parameter table has been successfully saved to: %s\n', csv_path);
end

function value_str = get_value_str(value)
    if ischar(value)
        value_str = value;
    elseif isstring(value)
        value_str = char(value);
    elseif isnumeric(value) && isscalar(value)
        value_str = num2str(value);
    elseif islogical(value)
        if value
            value_str = 'true';
        else
            value_str = 'false';
        end
    elseif isempty(value)
        value_str = '';
    else
        value_str = mat2str(value);
    end
end