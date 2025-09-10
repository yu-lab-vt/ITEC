function eig3 = cal_pc_3D(xx, yy, zz, xy, xz, yz) 

%% This function is to calculate the eigenvalues of the 3D Hessian matrix
% INPUT:    
%       xx, yy, zz, xy, xz, yz:elements of the Hessian matrix
% OUTPUT:   
%       eig3:the eigenvalues of the Hessian matrix

a = -(xx + yy + zz);
a = a(:);
b = -(yz.^2 + xy.^2 + xz.^2 - xx.*zz -yy.*zz -xx.*yy);
b = b(:);
c = -(xx.*yy.*zz + 2*xy.*yz.*xz - xx.*(yz.^2) - zz.*(xy.^2) - yy.*(xz.^2));
c = c(:);

p = b - a.^2/3;
q = 2*(a.^3)/27 - (a.*b)/3 + c;

eig3 = zeros(size(xx));
temp = 3*q./(2*p).*sqrt(-3./p);
temp = min(max(temp,-1),1);
eig3(:) = 2/sqrt(3)*(sqrt(-p)).*cos(1/3.*acos(temp)) - a/3;
eig3 = real(eig3);
end