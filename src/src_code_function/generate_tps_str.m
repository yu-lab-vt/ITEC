function tps_str = generate_tps_str(tif_files)

%% This function is to convert tif names to string format
% INPUT:
%     tif_files:struct of tif files information
% OUTPUT:
%     tps_str:string format of tif names

tps_str = strings(1, numel(tif_files));
for i = 1:numel(tif_files)
    [~, tps_str(i), ~] = fileparts(tif_files(i).name); 
end

end