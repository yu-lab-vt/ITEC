function [files, tps_to_process] = get_sorted_files(data_path, tps_to_process)

%% This function is to robustly finds and sorts image files (.tif) in a directory
% INPUT:
%     data_path:path of data
%     tps_to_process:indicating which files we would like to process
% OUTPUT:
%     files:name of useful files
%     tps_to_process:indicating which files we would like to process

tif_files = dir(fullfile(data_path, '*.tif'));

if ~isempty(tif_files)
    % ======== TIF handling ========
    num_list = cell(numel(tif_files), 1);
    max_digits = 0;
    for i = 1:numel(tif_files)
        tokens = regexp(tif_files(i).name, '\d+', 'match');
        num_list{i} = str2double(tokens);
        max_digits = max(max_digits, numel(tokens));
    end
    digit_matrix = NaN(numel(tif_files), max_digits);
    for i = 1:numel(tif_files)
        digits = num_list{i};
        digit_matrix(i, 1:numel(digits)) = digits;
    end
    std_devs = std(digit_matrix, 0, 1, 'omitnan');
    [~, var_col] = max(std_devs);
    digit_matrix = digit_matrix(:,var_col);
    tps_to_process = digit_matrix(ismember(digit_matrix,tps_to_process),1);
    if ~isempty(tps_to_process)
        tif_files = tif_files(ismember(digit_matrix,tps_to_process));
    end

    files = tif_files;
else
    error('No tif files found in the specified path.');
end

end
