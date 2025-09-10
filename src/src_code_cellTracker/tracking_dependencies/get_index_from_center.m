function idx = get_index_from_center(coo_yxz, data, shift)
% cur_tr: y ,x, z
if nargin == 2
    shift = [0 0 0];
elseif isscalar(shift)
    shift = [shift shift shift];
end
if size(data,1)==1 || size(data,2)==1
    hh = data(1);
    ww = data(2);
    zz = data(3);
else
    [hh, ww, zz] = size(data);
end
y = floor(coo_yxz(1))-shift(1):ceil(coo_yxz(1))+shift(1);
y(y<1 | y>hh) = [];
x = floor(coo_yxz(2))-shift(2):ceil(coo_yxz(2))+shift(2);
x(x<1 | x>ww) = [];
z = floor(coo_yxz(3))-shift(3):ceil(coo_yxz(3))+shift(3);
z(z<1 | z>zz) = [];
coos = combvec(y, x, z);
idx = sub2ind([hh,ww,zz],...
    coos(1,:)',coos(2,:)',coos(3,:)');