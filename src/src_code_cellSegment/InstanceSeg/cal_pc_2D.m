function eig2 = cal_pc_2D(xx,yy,xy)

%% This function is to calculate the eigenvalues of the 2D Hessian matrix
% INPUT:    
%       xx,yy,xy:elements of the Hessian matrix
% OUTPUT:   
%       eig2:the eigenvalues of the Hessian matrix

Mu = xx+yy;
Delta = sqrt(max(Mu.^2-4*(xx.*yy-xy.^2),0));
eig2 = (Mu+Delta)/2;

end