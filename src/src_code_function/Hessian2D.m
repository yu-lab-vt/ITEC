function [Dxx, Dyy, Dxy, F] = Hessian2D(Volume,Sigma)

%% This function is to calculate the Hessian matrix for 2D data
% INPUT:    
%       Volume:input 2D data
%       Sigma:the Gaussian smoothing factor
% OUTPUT:   
%       Dxx,Dyy,Dxy:the Hessian matrix for 2D data
%       F:filtered data

F = imgaussfilt3(Volume,Sigma);
clear Volume;
% Create first and second order differentiations
Dy = gradient3(F,'y');
Dyy = gradient3(Dy,'y');
clear Dy;

Dx = gradient3(F,'x');
Dxx = gradient3(Dx,'x');
Dxy = gradient3(Dx,'y');
clear Dx;