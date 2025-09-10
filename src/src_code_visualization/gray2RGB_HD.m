function out=gray2RGB_HD(label)

%% This function is to convert grayscale image into pseudo color image
% INPUT:
%      label:input grayscale image
% OUTPUT:
%      out:output color image

sz=size(label);
if length(sz)==2
    SZ=[sz(1:2) 1];
else
    SZ=[sz(1:2) 1 sz(3:end)];
end
L = reshape(label,SZ);
chOut=cell(1,1,3);
for clrCnt=1:3
    chOut{clrCnt}=L;
end
out=cell2mat(chOut);

end