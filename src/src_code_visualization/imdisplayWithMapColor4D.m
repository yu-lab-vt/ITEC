function outIm = imdisplayWithMapColor4D(orgIm3d, roi3d_org,varargin)

%% This function is to combine a 4D raw image with a 4D ROI data 
% to generate a colored labeled 4D output image
% INPUT:
%     orgIm3d:4D raw image
%     roi3d_org:4D ROI data
%     varargin:flag for color
% OUTPUT:
%     outIm:colored labeled 4D output image

roi3d=roi3d_org;
if ~isempty(varargin)&&varargin{1}=="accurate"
    V=connectivityBetweenCC_accurate4D(roi3d_org);
    IdxLst=mapColor(V);
    for i=1:length(IdxLst)
        roi3d(roi3d_org==i)=IdxLst(i);
    end   
end

colorIntensity = 0.5;
[h,w,z,t] = size(orgIm3d);
orgIm3d=mat2gray(double(orgIm3d));
orgIm3d=uint8(scale_image(orgIm3d, 0,255*(1-colorIntensity)));
outIm = zeros(h,w,3,z,t,"uint8");
nParticle = double(max(roi3d(:)));
cmap = uint8(jet(nParticle)*255)*colorIntensity;
cCnt = randperm(nParticle);

roi3d=reshape(roi3d,[h,w,1,z,t]);
orgIm3d=reshape(orgIm3d,[h,w,1,z,t]);

r = zeros(size(roi3d),"uint8");
g = zeros(size(roi3d),"uint8");
b = zeros(size(roi3d),"uint8");
N=int64(h)*int64(w)*int64(z)*int64(t);
for i=1:N
    j=roi3d(i);
    if j~=0
        r(i) = cmap(cCnt(j),1);
        g(i) = cmap(cCnt(j),2);
        b(i) = cmap(cCnt(j),3);
    end
end

outIm(:,:,1,:,:) = r + orgIm3d;
outIm(:,:,2,:,:) = g + orgIm3d;
outIm(:,:,3,:,:) = b + orgIm3d;

end