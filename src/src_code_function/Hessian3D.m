function [Dxx, Dyy, Dzz, Dxy, Dxz, Dyz, F] = Hessian3D(Volume,Sigma)

%% This function is to calculate the Hessian matrix for 2D data
% INPUT:    
%       Volume:input 3D data
%       Sigma:the Gaussian smoothing factor
% OUTPUT:   
%       Dxx, Dyy, Dzz, Dxy, Dxz, Dyz:the Hessian matrix for 3D data
%       F:filtered data

F = imgaussfilt3(Volume,Sigma);
clear Volume;
% Create first and second order differentiations
Dz = gradient3(F,'z');
Dzz = gradient3(Dz,'z');
clear Dz;

Dy = gradient3(F,'y');
Dyy = gradient3(Dy,'y');
Dyz = gradient3(Dy,'z');
clear Dy;

Dx = gradient3(F,'x');
Dxx = gradient3(Dx,'x');
Dxy = gradient3(Dx,'y');
Dxz = gradient3(Dx,'z');
clear Dx;