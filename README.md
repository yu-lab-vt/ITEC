# Readme for ITEC

* [Overview](#Overview)
* [Quickstart](#Quickstart)
* [Getting started with ITEC](#Getting started with ITEC)
    * [Input](#Input)
    * [Set Path and Parameters](#Set Path and Parameters)
    * [Set Path and Parameters (with parameter tables)](#Set Path and Parameters (with parameter tables))
    * [Output](#Output)
* [FAQ](#FAQ)

## Overview

ITEC is a high-precision, large-scale embryonic cell tracking platform dedicated to assisting developmental biologists in achieving whole-embryo lineage reconstruction and facilitating new biological discoveries. We provide the source code in MATLAB version along with a detailed user manual for reference.



## Quickstart

Running ITEC involves the following steps:

1. Code Download(link!)

1. Download the complete version of MATLAB (R2022b after is recommended)

   NOTE: When downloading MATLAB, please include at least the following toolboxes: `Image Processing Toolbox`,`Statistics and Machine Learning Toolbox`,`Parallel Computing Toolbox`.

   The download tutorial for MATLAB can be found in ***MATLAB Installation***.

1. Modify the parameter table

   This parameter table is in `.../ITEC-master/params.csv`, containing your input data path, output result path, and other adjustable parameters with biological or data characteristic significance. Suggest reading ***Getting started with ITEC*** section first, and then fine-tuning the parameters based on your own data.

1. Prepare your data

   ITEC supports input in TIFF format, with each frame stored as an independent TIFF file. Your data should be stored in the *data\_path* of the parameter table.

1. Run the pipeline

   For MATLAB with a visual interface, you can switch the current folder to `.../ITEC-master/src`, open `.../ITEC-master/src/demo.m` and click *run*.
   
   For MATLAB running via the command line, the following command needs to be run:
   
   ```
   cd YOUR_FOLDER/ITEC-master/src/ 
   nohup matlab -nodisplay -nosplash -nodesktop <demo.m >outinfo.txt &
   ```


1. Visualization

   The tracking results are saved in the *result\_path* of the parameter table. The results include the coordinates, frames, and parent-child relationships of all cells. You can use Mastodon (Fiji plugin for cell tracking analysis) to visualize the tracking results. For a detailed format of the results, please refer to ***Getting started with ITEC***. An easy-to-use tutorial for Mastodon can be found in ***Mastodon Usage***.


## Getting started with ITEC

### Input

   The typical input of ITEC contains the follows:

1. A 3D+t image sequence in TIFF format, with each frame stored as an independent .tif file. 
1. Cell tracking parameters related to your data. Please refer to ***Getting started with ITEC*** for the detailed meaning for parameters.

To input your dataset and set parameters, one way is to use the ITEC graphical interface, which is guided in ***Set Path and Parameters***. Run `ITEC.mlapp` with MATLAB to start the interface.

For remote users, you may also set those configurations in a CSV file directly. Templates of params.csv is available here(link!). After configuration, you can run the `demo.m` file with MATLAB to start the pipeline. Make sure your configuration file is named as params.csv under `.../ITEC-master/src/` directory.

### Set Path and Parameters (with UI interface)


#### 1. Import

   On the *Import* page, you can set the path to load your dataset and output tracking results. You may also set the frame range you want to analyze.    
   
   To import your .csv of parameters directly, click ‘I want to import parameters directly from a parameter file’ on the *import* page, and set the path to load the file. Path and parameters will be loaded automatically.

   <img width="612" height="375" alt="图片" src="https://github.com/user-attachments/assets/6814b2ed-c3e4-421d-83d9-54dcf02c31f9" />

   <img width="538" height="225" alt="图片" src="https://github.com/user-attachments/assets/dc4bb42a-2575-40ce-b4c6-245b7f19ee10" />


#### 2. General Parameters

   ----------Resolution----------

   **z-x/y ratio** : the ratio of Z resolution OVER X/Y resolution. Z resolution refers to the distance between z-layers, and X/Y resolution refers to the distance between neighboring pixels. For example, if each pixel between x and y in a dataset represents 0.25 μm, and the distance between adjacent z-layers is 1 μm, then the z-x/y ratio should be set to 4. Most datasets are anisotropic, meaning the z-x/y ratio is usually greater than 1.

   **Cell size** : the volume range of cells, unit in voxels. The algorithm will not detect cells beyond that range, so generally a loose range is preferred.

   **Downsampling ratio** : the ratio of downsizing xy plane to speed up the processing. For example, a ratio of 2 will rescale a slice of 1920 \* 1080 to 960 \* 540. This ratio should be no more than z-x/y ratio to ensure detection performance.

   <img width="535" height="339" alt="图片" src="https://github.com/user-attachments/assets/a1806715-8656-4906-99b6-9e885b547f75" />

   ----------Grayscale----------

   **Intensity upper bound** : Pixels whose grayscale is above that bound will be set to that bound to ensure the contrast between pixels. We recommend choosing the upper intensity quantile of cells as this bound.

   **Intensity lower bound** : Similar to the upper bound, the algorithm will reset pixels below that bound to 0 and further enhance contrast. We recommend setting the lower intensity quantile of the background region as this bound.

   **Background intensity** : a general threshold of the background grayscale. Cells with grayscale below the threshold won’t be detected.

   <img width="540" height="336" alt="图片" src="https://github.com/user-attachments/assets/b88192cf-86c0-49c7-9b8e-588d89303454" />

   ----------Smoothing----------

   **Filter factor** : the standard deviation of the Gaussian filter used for smoothing. You can increase it to get more consistent segmentation. Usual range is [1, 5].

#### 3. Processing Parameters

   ----------Segmentation----------

   **Save visualization results** : flags whether to save the visualization results. The segmentation result of each frame will be saved as a TIFF file. You may choose no to speed up the process.

   **smFactor** : can increase it to prevent over-segmentation. Usual range is [0.2, 2].

   **curvesThres** : The threshold of detecting seeds for core regions, usually -5. If too many cells are detected, you should lower this value; if too few cells are detected, you should increase it (up to -3). 

   **foreThres** : The threshold of detecting boundaries, usually +3. Can be lowered to down to +1 to encourage boundary detection.

   **Intensity difference** : Usually 0. Can increase it to get better segmentation result given that the grayscale difference between the cells and background is distinct.

   <img width="584" height="345" alt="图片" src="https://github.com/user-attachments/assets/e170bbf1-7346-4527-92a7-520d53fa8b2d" />

   ----------Tracking----------

   **maxIter** : The max number of iteration steps of error correction. Usually 3~5 is enough for convergence. Can increase it if results vary much with the iterations.

   **division factor** : The confidence level for division detection. Can increase it to detect more divisions. Usual range is [0.9, 1].

   **Save augmented seg. Results** : flags whether to save the segmentation results after error-correction-based tracking. Note that the error correction process may change the previous segmentation result to achieve better linkage.

   **Use motion flow estimation** : flags whether to apply motion flow methods during registration. The use of motion flow often achieves better results.

   **max distance** : a rough bound of the maximum displacement in pixels from frame t to t+1 (e.g. in division case, the displacement from the division spot to the location of a child in the next frame). It is used to exclude too far transition between frames. Usually 50 is fine. You may decrease it if you find some unreasonable transitions.

   <img width="590" height="435" alt="图片" src="https://github.com/user-attachments/assets/d80d99e9-82c3-4a32-ba15-b561e4618656" />
   
#### 4. Start Tracking

   After you have set all the parameters, turn to the *Start Tracking* page. Click *save* button to save path and parameters above. Then click *Run* button to start ITEC!

   <img width="603" height="435" alt="图片" src="https://github.com/user-attachments/assets/ec642505-31ff-4f24-9025-f0997f4ae4df" />
   
### Set Path and Parameters (with parameter tables)


### Output
   The output of ITEC contains the follows: 

1. A standard CSV file, which succinctly contains the unique ID, XYZ coordinates, frames, and the parent ID associated with the previous frame of all cells.

1. TGMM format that can be directly opened by Mastodon, including accompanying h5/xml. Regarding the use of Mastodon, you can refer to ***Mastodon usage***.

You can find all of the output in your *result\_path*. If you are not satisfied with the results, you may adjust the parameters and run again. If you have any difficulties tuning the parameters, please refer to ***FAQ*** or contact us at [github](https://github.com/yu-lab-vt/ITEC).

   

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

   Our paper can be found here(link!). If you have any questions about the method, please contact <yug@tsinghua.edu.cn>



## Citing
