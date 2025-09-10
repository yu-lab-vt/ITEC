function strel_ker = getKernel(strel_rad)
    
    zRatio = strel_rad(1)/strel_rad(3);
    strel_ker = ones(strel_rad(1)*2+1, strel_rad(2)*2+1,ceil(strel_rad(3))*2+1);
    [xx,yy,zz] = ind2sub_direct(size(strel_ker), find(strel_ker));
    dist = sqrt((xx-strel_rad(1)-1).^2 + (yy-strel_rad(2)-1).^2 + ((zz-strel_rad(3)-1)*zRatio).^2);
    strel_ker(dist>=strel_rad(1)) = 0;
    strel_ker = strel(strel_ker);
end