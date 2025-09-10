function write4dTiffRGB(dat,ImName)

%% This function is to convert 4D data to tif format
% INPUT:
%    dat:original data
%    ImName:tif name

dat = uint8(dat);
fiji_descr = ['ImageJ=1.52p' newline ...
            'images=' num2str(size(dat,4)*...
                              size(dat,5)) newline... 
            'slices=' num2str(size(dat,4)) newline...
            'frames=' num2str(size(dat,5)) newline... 
            'hyperstack=true' newline...
            'mode=RGB color' newline...  
            'loop=false' newline...  
            'min=' num2str(min(dat(:))) newline...      
            'max=' num2str(max(dat(:)))];  % change this to 256 if you use an 8bit image
            
t = Tiff(ImName,'w');
tagstruct.ImageLength = size(dat,1);
tagstruct.ImageWidth = size(dat,2);
tagstruct.Photometric = Tiff.Photometric.RGB;
tagstruct.BitsPerSample = 8;
tagstruct.SamplesPerPixel = size(dat,3);
tagstruct.Compression = Tiff.Compression.LZW;
tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
tagstruct.SampleFormat = Tiff.SampleFormat.UInt;
tagstruct.ImageDescription = fiji_descr;
for frame = 1:size(dat,5)
    for slice = 1:size(dat,4)
        t.setTag(tagstruct)
        t.write(im2uint8(dat(:,:,:,slice,frame)));
        t.writeDirectory(); % saves a new page in the tiff file
    end
end
t.close() 

end