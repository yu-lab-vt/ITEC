# ITEC

* [Overview](#Overview)
* [Getting started with ITEC](#Getting-started-with-ITEC)
    * [Preparation](#Preparation)
    * [Start ITEC](#Start-ITEC)
    * [Set Path and Parameters](#Set-Path-and-Parameters)
    * [Output and Visualization](#Output-and-Visualization)
    * [Parameter Fine-Tuning](#Parameter-Fine-Tuning)
* [Theory support](#Theory-support)
* [Citing](#Citing)

## Overview

ITEC is a high-precision, large-scale embryonic cell tracking platform dedicated to assisting developmental biologists in achieving whole-embryo lineage reconstruction and facilitating new biological discoveries. We provide the source code in MATLAB version along with a detailed user manual for reference.


## Getting started with ITEC

### Preparation

1. **Code Download**

   [Download](https://github.com/yu-lab-vt/ITEC/archive/refs/heads/main.zip) the code and unzip it to your working directory.

2. **MATLAB Installation**

   Version Requirement: R2022b or later is recommended

   Toolbox Requirement:  `Image Processing Toolbox`,`Statistics and Machine Learning Toolbox`,`Parallel Computing Toolbox`.

   A download tutorial for MATLAB can be found in [MATLAB Installation](documents/MATLAB%20Installation.md).

4. **Data Preparation**

   ITEC supports raw data in TIFF format, with each frame stored as an independent TIFF file.

### Start ITEC

For MATLAB GUI users, run `ITEC.mlapp` in `./ITEC-main/src/` to start the interface.

For remote users, please first follow the guide in [Set Path and Parameters](#Set-Path-and-Parameters) to tune your parameters in `./ITEC-main/src/params.csv`. Then run the `demo.m` using the following commands:
   
```
cd YOUR_FOLDER/ITEC-main/src/ 
nohup matlab -nodisplay -nosplash -nodesktop <demo.m>outinfo.txt &
```

### Set Path and Parameters


<details id="Set-path-and-parameters-with-gui-interface">
<summary> Set Path and Parameters with GUI interface (for MATLAB GUI users) </summary>

#### 1. Import

   On the *Import* page, you can set the path to load your dataset and output tracking results. You may also set the frame range you want to analyze.   

   
   You may also import your .csv of parameters directly **if you have runned ITEC previously**. Click ‘I want to import parameters directly from a parameter file’ on the *import* page, and set the path to load the file. Path and parameters will be loaded automatically. Please refer to [Set Path and Parameters (with parameter table)](#Set-path-and-parameters-with-parameter-table) for their names in table.

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

   **max distance** : a rough bound of the maximum displacement in pixels from frame t to t+1 (e.g. in division case, the displacement from the division spot to the location of a child in the next frame). It is used to exclude too far motion between frames. Usually 50 is fine. You may decrease it if you find some unreasonable linkages.
   

  <img width="504" height="378" alt="幻灯片3" src="https://github.com/user-attachments/assets/56efe5e7-1128-4c6e-8186-c85a224de0d4" />
  

   
#### 4. Start Tracking

   After you have set all the parameters, turn to the *Start Tracking* page. Click *save* button to save path and parameters above. Then click *Run* button to start ITEC!
   

  <img width="504" height="378" alt="幻灯片4" src="https://github.com/user-attachments/assets/84a1e7fd-9637-4dd1-b9bf-4590020d9b84" />
  


</details>

<details id="Set-path-and-parameters-with-parameter-table">
<summary> Set Path and Parameters with parameter table (for remote users) </summary>

#### 1. General Parameters

   <div>

   | Params | Name in UI | Descrption | Comments |
   | ---------- | -----------| ----------|---------|
   | *z\_resolution*   | z-x/y ratio | the ratio of Z resolution OVER X/Y resolution. Z resolution refers to the distance between Z layers, and X/Y resolution refers to the distance between neighbouring pixels | For example, if each pixel between x and y in a dataset represents 0.25 μm, and the distance between adjacent z-layers is 1 μm, then the z-x/y ratio should be set to 4. Most datasets are anisotropic, meaning the z-x/y ratio is usually greater than 1 |
   | *minSize* | Cell Size | the volume lower bound of cells along xy plane, unit in voxels | The algorithm will not detect cells below that bound, so generally a loose threshold is preferred |
   | *maxSize* | Cell Size | the volume upper bound of cells along xy plane, unit in voxels | The algorithm will not detect cells beyond that bound, so generally a loose threshold is preferred |
   | *scale\_term* | Intensity upper bound | Pixels whose grayscale is above that bound will be set to that bound to ensure the contrast between pixels | You can choose the upper intensity quantile as this bound |
   | *clipping* | Intensity lower bound | Similar to the upper bound, the algorithm will reset pixels below that bound to 0 and further enhance contrast | You can set the lower intensity quantile of the background region as this bound |
   | *bgIntensity* | Background intensity | a general threshold of the background grayscale. Cells with intensity below the threshold won’t be detected | You can use ImageJ to help you set an approximate value |
   | *filter\_sigma* | Filter factor | the standard deviation of the Gaussian filter used for smoothing. | You can increase it to get more consistent segmentation. Usual range is [1, 5] |
   
   </div>

#### 2. Segmentation Parameters
   
   <div>

   | Params | Name in UI | Descrption | Comments |
   | ---------- | -----------| ----------|---------|
   | *visualization*   | Save visualization results | flags whether to save the visualization results. The segmentation result of each frame will be saved as a TIFF file | You may choose no to speed up the process |
   | *smFactor* | smFactor | controls the power of segmentation | You can increase it to prevent over-segmentation. Usual range is [0.2, 2] |
   | *curvesThres* | curvesThres | The threshold of detecting seeds for core regions | Usually -5. If too many cells are detected, you should lower this value; if too few cells are detected, you should increase it (up to -3) |
   | *foreThres* | foreThres | The threshold of detecting boundaries | Usually +3. Can be lowered to down to 1 to encourage boundary detection |
   | *diffIntensity* | Intensity difference | controls segmentation based on intensity difference between the cells and background | Usually 0. Can increase it to get better segmentation results when the difference is distinct |
   
   </div>


#### 3. Tracking Parameters
   
   <div>

   | Params | Name in UI | Descrption | Comments |
   | ---------- | -----------| ----------|---------|
   | *maxIter*   | maxIter | The max number of iteration steps of error correction | Usually 3~5 is enough for convergence. Can increase it if results vary much with the iterations |
   | *division\_thres* | division factor | The confidence level for division detection | Can increase it to detect more divisions. Usual range is [0.9, 1] |
   | *saveAllResults* | Save augmented seg. Results | flags whether to save the segmentation results after error-correction-based tracking | Note that the error correction process may change the previous segmentation result to achieve better linkage |
   | *useMotionFlow* | Use motion flow estimation | flags whether to apply motion flow methods during registration | The use of motion flow often achieves better results |
   | *max\_dist* | max distance | a rough bound of the maximum displacement in pixels from frame t to t+1 | It is used to exclude too far transition between frames. Usually 50 is fine. You may decrease it if you find some unreasonable linkages |
   
   </div>

</details>

### Output and Visualization


   The output of ITEC (in your *result\_path*) contains the follows: 

   1. A standard CSV file, which succinctly contains the unique ID, XYZ coordinates, frames, and parent-child relationships of all cells.

   2. TGMM format and accompanying h5/xml that can be directly opened by Mastodon (Fiji plugin for cell tracking analysis). An easy-to-use tutorial for Mastodon can be found in [Mastodon Usage](documents/Mastodon%20Usage.md).



### Parameter Fine-Tuning

* We provide [Examples](examples/README.md) of zebrafish embryo development data along with corresponding parameters, which users can directly download and run.

* We compile some common parameter tuning questions. Please refer to [FAQ](documents/FAQ.md).

## Theory Support

   Our paper can be found here. If you have any questions about ITEC, please contact <yug@tsinghua.edu.cn>



## Citing
