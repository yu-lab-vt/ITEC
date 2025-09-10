function [output1, output2] = matfiles2cell_scaling(folder, foldertype, names, sc_f, st_loc, sz_crop)
% read the mat files under a given folder. concatnate them into cells.
% if names is given, then only read those mat files with given name.

if nargin == 1
    names = [];
end

files = dir(fullfile(folder, '*.mat'));
if ~isempty(names)
    files(numel(names)+1:end) = [];
    for f = 1:numel(names)
        files(f).name = names(f) + '.mat';
    end
end
output1 = cell(numel(files), 1);
output2 = cell(numel(files), 1);
for f = 1:numel(files)
    if strcmp(foldertype, 'refine_res')
        m = load(fullfile(files(f).folder, files(f).name),'refine_res', 'threshold_res');
        output1_tmp{1} = m.refine_res;
        output2_tmp{1} = m.threshold_res;

        [output1_tmp, ~, ~, output2_tmp, ~] = data_scaling(sc_f, st_loc, ...
            sz_crop, output1_tmp, {}, {}, output2_tmp, {});
        output1{f} = output1_tmp{1};
        output2{f} = output2_tmp{1};
        
    elseif strcmp(foldertype,'priCvt_res')
        m = load(fullfile(files(f).folder, files(f).name), 'eig_res_2d', 'eig_res_3d');
        output_tmp{1} = cell(2,1);
        output_tmp{1}{1} = m.eig_res_2d;
        output_tmp{1}{2} = m.eig_res_3d;

        [~, ~, ~, ~, output_tmp] = data_scaling(sc_f, st_loc, ...
            sz_crop, {}, {}, {}, {}, output_tmp);
        output1{f} = output_tmp{1}{1};
        output2{f} = output_tmp{1}{2};     

    elseif strcmp(foldertype,'priCvt')
        m = load(fullfile(files(f).folder, files(f).name), 'eig_res_3d');
        output_tmp{1} = cell(2,1);
        output_tmp{1}{1} = m.eig_res_3d;
        output_tmp{1}{2} = m.eig_res_3d;

        [~, ~, ~, ~, output_tmp] = data_scaling(sc_f, st_loc, ...
            sz_crop, {}, {}, {}, {}, output_tmp);
        output1{f} = output_tmp{1}{1};
        output2{f} = output_tmp{1}{2};     

    else
        error("undefined file type");
    end
end
end