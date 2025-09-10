function connectTable=connectivityBetweenCC_accurate4D(cellMap_org)

%% This function is to compute adjacency of connected components in a 4D volume via dilation
% INPUT:
%     cellMap_org : 4D array [X, Y, Z, T]. 
%                 0 = background, positive integers = component labels.
% OUTPUT:
%     connectTable: N x N logical symmetric matrix. 
%                 connectTable(i,j) = true if components i,j are adjacent.
%                 N = max(cellMap_org(:)).

gapSize=2;
Mid=gapSize+1;
PadSz=gapSize*2+1;
cellMap = padarray(cellMap_org,gapSize*ones(1,4),0,'both');
N=max(cellMap(:));
SZ=size(cellMap);
SZ_cum=cell(4,1);
SZ_cum{1}=1;SZ_cum{2}=SZ(1);
SZ_cum{3}=SZ_cum{2}*SZ(2);
SZ_cum{4}=SZ_cum{3}*SZ(3);

PixelIdxList=cell(N,1);
for cnt=1:N
    disp("dilate: "+cnt+"/"+N);
    tempIdxLst=find(cellMap==cnt);
    L=length(tempIdxLst);
    tempIdxLst_pad=zeros(L,4,PadSz);
    for i=1:PadSz
        for j=1:4
            tempIdxLst_pad(:,j,i)=tempIdxLst+(i-Mid)*SZ_cum{j};
        end
    end
    tempIdxLst_pad=unique(tempIdxLst_pad(:));
    PixelIdxList{cnt}=setdiff(tempIdxLst_pad,tempIdxLst);
end

connectTable=false(N,N);
parfor i=1:N
    disp("connect: "+i+"/"+N);
    for j=1:N
        flag=~isempty(intersect(PixelIdxList{i},PixelIdxList{j}));
        connectTable(i,j)=flag;
    end
end

end