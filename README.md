# Readme for ITEC

* [Overview](#Overview)
* [Getting started with ITEC](#Getting-started-with-ITEC)
    * [Preparation](#Preparation)
    * [Start ITEC Program](#Start-ITEC-Program)
    * [Set Path and Parameters](#Set-Path-and-Parameters)
    * [Outputs](#Outputs)
* [FAQ](#FAQ)
* [Theory support](#Theory-support)
* [Citing](#Citing)

## Overview

ITEC is a high-precision, large-scale embryonic cell tracking platform dedicated to assisting developmental biologists in achieving whole-embryo lineage reconstruction and facilitating new biological discoveries. We provide the source code in MATLAB version along with a detailed user manual for reference.


## Getting started with ITEC

### Preparation

1. **Code Download**

   Download the full code of ITEC on github. Then unzip it to your working directory.

2. **MATLAB Installation**

   Download the complete version of MATLAB (R2022b after is recommended)

   When downloading MATLAB, please include at least the following toolboxes: `Image Processing Toolbox`,`Statistics and Machine Learning Toolbox`,`Parallel Computing Toolbox`. You can also install these toolboxes afterwards.

   A download tutorial for MATLAB can be found in [MATLAB Installation](documents/MATLAB%20Installation.md).

3. **Data Preparation**

   ITEC supports input in TIFF format, with each frame stored as an independent TIFF file.

### Start ITEC

For MATLAB with a graphical user interface(GUI), run `ITEC.mlapp` under `.../ITEC-master/src/` directory with MATLAB to start the interface.

For remote users, please first follow the guide in ***Set Path and Parameters*** to tune your parameters in `.../ITEC-master/src/params.csv`. Then run the `demo.m` using the following commands:
   
```
cd YOUR_FOLDER/ITEC-master/src/ 
nohup matlab -nodisplay -nosplash -nodesktop <demo.m>outinfo.txt &
```

### Set Path and Parameters

For MATLAB GUI users, please refer to **Set Path and Parameters (with GUI interface)** to tune your parameters.

For remote users, please refer to **Set Path and Parameters (with parameter table)** to tune your parameters.

We provide [Examples](examples/README.md) of zebrafish embryo development data along with corresponding parameters, which users can directly download and run.

<details>
<summary> Set Path and Parameters (with GUI interface) </summary>

#### 1. Import

   On the *Import* page, you can set the path to load your dataset and output tracking results. You may also set the frame range you want to analyze.   

   
   You may also import your .csv of parameters directly **if you have runned ITEC previously**. Click ‘I want to import parameters directly from a parameter file’ on the *import* page, and set the path to load the file. Path and parameters will be loaded automatically. Please refer to ***Set Path and Parameters (with parameter table)*** for their names in table.

   <img width="504" height="378" alt="幻灯片1" src="https://github.com/user-attachments/assets/ba514c31-9d37-469e-8200-35ca6bbcd061" />


#### 2. General Parameters

   ----------Resolution----------

   **z-x/y ratio** : the ratio of Z resolution OVER X/Y resolution. Z resolution refers to the distance between z-layers, and X/Y resolution refers to the distance between neighboring pixels. For example, if each pixel between x and y in a dataset represents 0.25 μm, and the distance between adjacent z-layers is 1 μm, then the z-x/y ratio should be set to 4. Most datasets are anisotropic, meaning the z-x/y ratio is usually greater than 1.

   **Cell size** : the volume range of cells, unit in voxels. The algorithm will not detect cells beyond that range, so generally a loose range is preferred.

   **Downsampling ratio** : the ratio of downsizing xy plane to speed up the processing. For example, a ratio of 2 will rescale a slice of 1920 \* 1080 to 960 \* 540. This ratio should be no more than z-x/y ratio to ensure detection performance.


   ----------Grayscale----------

   **Intensity upper bound** : Pixels whose grayscale is above that bound will be set to that bound to ensure the contrast between pixels. We recommend choosing the upper intensity quantile of cells as this bound.

   **Intensity lower bound** : Similar to the upper bound, the algorithm will reset pixels below that bound to 0 and further enhance contrast. We recommend setting the lower intensity quantile of the background region as this bound.

   **Background intensity** : a general threshold of the background grayscale. Cells with grayscale below the threshold won’t be detected.


   ----------Smoothing----------

   **Filter factor** : the standard deviation of the Gaussian filter used for smoothing. You can increase it to get more consistent segmentation. Usual range is [1, 5].
   

<img width="504" height="378" alt="幻灯片2" src="https://github.com/user-attachments/assets/b4b3067b-ee38-496d-8fa2-818feb3ced39" />

      

#### 3. Processing Parameters

   ----------Segmentation----------

   **Save visualization results** : flags whether to save the visualization results. The segmentation result of each frame will be saved as a TIFF file. You may choose no to speed up the process.

   **smFactor** : can increase it to prevent over-segmentation. Usual range is [0.2, 2].

   **curvesThres** : The threshold of detecting seeds for core regions, usually -5. If too many cells are detected, you should lower this value; if too few cells are detected, you should increase it (up to -3). 

   **foreThres** : The threshold of detecting boundaries, usually +3. Can be lowered to down to +1 to encourage boundary detection.

   **Intensity difference** : Usually 0. Can increase it to get better segmentation result given that the grayscale difference between the cells and background is distinct.
   
   

   ----------Tracking----------

   **maxIter** : The max number of iteration steps of error correction. Usually 3~5 is enough for convergence. Can increase it if results vary much with the iterations.

   **division factor** : The confidence level for division detection. Can increase it to detect more divisions. Usual range is [0.9, 1].

   **Save augmented seg. Results** : flags whether to save the segmentation results after error-correction-based tracking. Note that the error correction process may change the previous segmentation result to achieve better linkage.

   **Use motion flow estimation** : flags whether to apply motion flow methods during registration. The use of motion flow often achieves better results.

   **max distance** : a rough bound of the maximum displacement in pixels from frame t to t+1 (e.g. in division case, the displacement from the division spot to the location of a child in the next frame). It is used to exclude too far transition between frames. Usually 50 is fine. You may decrease it if you find some unreasonable transitions.
   

  <img width="504" height="378" alt="幻灯片3" src="https://github.com/user-attachments/assets/56efe5e7-1128-4c6e-8186-c85a224de0d4" />
  

   
#### 4. Start Tracking

   After you have set all the parameters, turn to the *Start Tracking* page. Click *save* button to save path and parameters above. Then click *Run* button to start ITEC!
   

  <img width="504" height="378" alt="幻灯片4" src="https://github.com/user-attachments/assets/84a1e7fd-9637-4dd1-b9bf-4590020d9b84" />
  


</details>

<details>
<summary> Set Path and Parameters (with parameter table) </summary>

#### 1. General Parameters

   <div>

   | Params | Name in UI | Descrption | Comments |
   | ---------- | -----------| ----------|---------|
   | *z\_resolution*   | z-x/y ratio | the ratio of Z resolution OVER X/Y resolution. Z resolution refers to the distance between Z layers, in um typically. X/Y resolution refers to the real distance between neighbouring pixels | Your may derive the X/Y resolution by dividing the real length of the scope(1mm, e.g.) by the number of pixels along X direction(700, e.g.). The typical ratio should be no less than 1 |
   | *minSize* | Cell Size | the area lower bound of cells along xy plane, unit in pixels | The algorithm will not detect cells below that bound, so generally a loose threshold is preferred |
   | *maxSize* | Cell Size | the area upper bound of cells along xy plane, unit in pixels | The algorithm will not detect cells beyond that bound, so generally a loose threshold is preferred |
   | *scale\_term* | Intensity upper bound | Pixels whose grayscale is above that bound will be set to that bound to ensure the contrast between pixels | You may use ImageJ to choose the upper quantile of the intensity as this bound |
   | *clipping* | Intensity lower bound | Similar to the upper bound, the algorithm will reset pixels below that bound to 0 and further enhance contrast | For generally dark data, 0 should be fine, while it can be increased when the background noise is generally high |
   | *bgIntensity* | Background intensity | a general threshold of the grayscale of the background compared to the cells. Cells with intensity below that threshold won’t be detected | You may use ImageJ to help you set an approximate value |
   | *filter\_sigma* | Filter factor | the intensity of the Gaussian filter used to highlight signals. | You can increase it when background noise is high, or to get more conservative  segmentation. Usual range is [1, 5] |
   
   </div>

#### 2. Segmentation Parameters
   
   <div>

   | Params | Name in UI | Descrption | Comments |
   | ---------- | -----------| ----------|---------|
   | *visualization*   | Save visualization results | flags whether to save the visualized results | You may choose no to speed up the process |
   | *smFactor* | smFactor | controls the power of segmentation | You can increase it to prevent over-segmentation. Usual range is [0.3, 2] |
   | *curvesThres* | curvesThres | The threshold of detecting seeds for core regions | Usually -5. Can be increased to up to -3 to encourage cellular core detection |
   | *foreThres* | foreThres | The threshold of detecting boundaries | Usually +3. Can be lowered to down to 1 to encourage boundary detection |
   | *diffIntensity* | Intensity difference | controls segmentation based on intensity difference between the cells and background | Usually 0. Can increase it to get better segmentation results when the difference is distinct |
   
   </div>


#### 3. Tracking Parameters
   
   <div>

   | Params | Name in UI | Descrption | Comments |
   | ---------- | -----------| ----------|---------|
   | *maxIter*   | maxIter | The max number of iteration steps of error correction | Usually 3~5 is enough for convergence. Can increase it if results vary much with the iterations |
   | *division\_thres* | division factor | The intensity of detecting divisions | Can increase it to detect more divisions. Usual range is [0.9, 1] |
   | *saveAllResults* | Save augmented seg. Results | flags whether to save the segmentation results after error-correction-based tracking | Note that the error correction process may change the previous segmentation result to achieve better linkage |
   | *useMotionFlow* | Use motion flow estimation | flags whether to apply motion flow methods during registration | The use of motion flow often achieves better results |
   | *max\_dist* | Max distance | a rough bound of the maximum displacement in pixels from frame t to t+1 | It is used to exclude too far transition between frames. Usually 50 is fine. You may decrease it if you find some unreasonable transitions |
   
   </div>

</details>

### Outputs

* **ITEC Output and Visualization**

   The output of ITEC contains the follows: 

   1. A standard CSV file, which succinctly contains the unique ID, XYZ coordinates, frames, and parent-child relationships of all cells.

   2. TGMM format and accompanying h5/xml that can be directly opened by Mastodon (Fiji plugin for cell tracking analysis). An easy-to-use tutorial for Mastodon can be found in [Mastodon Usage](documents/Mastodon%20Usage.md).


   You can find all of the output in your *result\_path*. If you are not satisfied with the results, you can adjust the parameters and run again. If you have any difficulties tuning the parameters, please refer to ***FAQ*** or contact us.


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



## Theory Support

   Our paper can be found here. If you have any questions about the method, please contact <yug@tsinghua.edu.cn>



## Citing
