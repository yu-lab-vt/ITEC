function imo = scale_image(im, vlow, vhigh, ilow, ihigh)

%% This function is to linearly scale the input image IM to the range [vlow, vhigh]
% from the range [ilow ihigh] (if provided)
% INPUT:
% im:original image
% vlow,vhigh:target range after scaling
% ilow,ihigh:original range
% imo:image after scaling

if nargin == 3
    ilow = min(im(:));
    ihigh = max(im(:));
else
    if isempty(ilow)
        ilow = min(im(:));
    end
    if isempty(ihigh)
        ihigh = max(im(:));
    end
end
imo = (im-ilow)/(ihigh-ilow) * (vhigh-vlow) + vlow;

end