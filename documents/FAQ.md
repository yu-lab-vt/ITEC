## FAQ

#### 1. I found a lot of cells over-segmented in the result. How can I tune the parameters?

　This problem may result from distinct noise or too intensive segmentation. Accordingly, you may tune up the <ins>Filter factor</ins> in *Smoothing* section, or the <ins>smFactor</ins> in *Segmentation* section.

#### 2. I found a lot of cells under-segmented in the result. How can I tune the parameters?

　In *Smoothing* section, make sure your <ins>Filter factor</ins> is not set too high as it may fuse cell boundaries. Also, you may tune down the <ins>smFactor</ins> in *Segmentation* section and see if it works.

#### 3. I want to track the cells within a certain size range. What should I do?

　In *Resolution* section, you can adjust the cell size parameters (<ins>max size</ins> & <ins>min size</ins>) to achieve that. The algorithm will exclude cells beyond that range. For example, if you do not want the small cells, you may tune up the min size a little bit to get rid of them.

#### 4. I found part of the detections that ITEC provided seem not to be true cells. How can I tune the parameters?

　Most of the time this situation results from a too-low <ins>Background intensity</ins> in *Grayscale* section. Try tune it up to a proper level to distinguish the cells. You may further check other *Grayscale* parameters if it does not work.

#### 5. I found many cells missing, or fragmented tracks. How can I tune the parameters?

　You may first check if your *Grayscale* parameters are set properly. As ITEC remaps the intensity based on <ins>upper/lower bounds</ins> during pre-processing, a smaller range is better to show the contrast in between. Also make sure the <ins>Background intensity</ins> is set appropriately within the bounds, not too high. 

　On top of that, you may tune up the <ins>curveThres</ins> a little bit in *advanced parameters for segmentation*. Framented track may also result from a low <ins>max distance</ins> setting in *advanced parameters for tracking*, with data of compromised time resolution.

#### 6. I found ITEC detected few/too many divisions. How can I tune the parameters?

　Division detection is mainly controlled by the <ins>division factor</ins> in *Tracking* section. Try tune it up a bit to encourage more detections of divsion, and vice versa. If the time resolution of your data is compromised, you may tune up the <ins>max distance</ins> in *advanced parameters for tracking* to allow more vibrant transitions.

#### 7. I found ITEC takes a long time at every stage. Is there anything wrong?

　ITEC leverages parallel computing for acceleration, so make sure you have install the `parallel computing toolbox` on MATLAB before processing. Also, try to crop the raw data into ceratin region of interest before importing it into ITEC.

　As for parameters, for large scale data with good z-x/y ratios, you can set the <ins>Downsampling ratio</ins> in *Resolution* section above 1 to further accelerate the process. Besides, make sure your <ins>maxIter</ins> in *Tracking* section is not too large. 
