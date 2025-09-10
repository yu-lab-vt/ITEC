# Readme for ITEC


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



## MATLAB Installation


   Please refer to the MATLAB official websites for [downloads](https://ww2.mathworks.cn/downloads/) and [installation guide](https://ww2.mathworks.cn/help/install/ug/install-products-with-internet-connection.html). Many schools and research institutions offer free MATLAB. For licensing issues with MATLAB, please consult your institution. Note that the toolboxes `Image Processing Toolbox` `Statistics and Machine Learning Toolbox` `Parallel Computing Toolbox` need to be installed during MATLAB installation.

   **If you are using a server without a graphical interface**, you can install MATLAB as follows:

1. Download the MATLAB version for the server via your PC, and then upload it to the server. The following guide takes MATLAB R2023a as an example.

1. Mount the ISO file.
   ```
   mkdir /mnt/matlab
   mount -o loop ISO_FILE_DIRECTORY /mnt/matlab
   mkdir /mnt/Matlab_R2023a
   ```
1. Edit installation configs.
   ```
   touch /mnt/installer_input.txt
   vim /mnt/installer_input.txt
   # Press i to change into edit mode
   # Enter the following lines---------
   destinationFolder=/mnt/Matlab_R2023a
      fileInstallationKey=XXXXX-XXXXX-XXXXX-XXXXX-XXXXX-XXXXX(Your installation key)
      agreeToLicense=yes
      outputFile=/mnt/matlab_install.log
      licensePath=YOUR_LICENSE_DIRECTORY
   # Press Esc to exit edit mode
   # Enter wq to save and quit
   ```
1. Install MATLAB.
   ```
   sudo chmod 444 /mnt/installer_input.txt
   cd /mnt/matlab
   chmod a+x -R ./*
   cd /mnt/Matlab_R2023a
   chmod a+x -R ./
   sudo /mnt/matlab/install -inputFile ./installer_input.txt
   ```
1. Validate installation.
   ```
   /mnt/Matlab_R2023a/bin/matlab
   # Enter `bash /Matlab_R2023a/bin/activate_matlab.sh` if not activated
   sudo umount /mnt/matlab
   ```



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


### Check output and re-tune parameters
   The output of ITEC contains the follows: 

1. A standard CSV file, which succinctly contains the unique ID, XYZ coordinates, frames, and the parent ID associated with the previous frame of all cells.

1. TGMM format that can be directly opened by Mastodon, including accompanying h5/xml. Regarding the use of Mastodon, you can refer to ***Mastodon usage***.

You can find all of the output in your *result\_path*. If you are not satisfied with the results, you may adjust the parameters and run again. If you have any difficulties tuning the parameters, please refer to ***FAQ*** or contact us at [github](https://github.com/yu-lab-vt/ITEC).

   

## Mastodon usage


#### 1. Start Fiji/ImageJ and get Mastodon.
   Start the updater.

   <img width="381" height="269" alt="图片" src="https://github.com/user-attachments/assets/b9b1095b-ac42-4bcc-bff2-0786a834e41c" />

   Click on the Manage update sites button, and search for Mastodon in the site management dialog. Select all the three sites by Mastodon. Then click Apply and Close and Apply Changes in turn. Restart ImageJ as guided.

   <img width="389" height="300" alt="图片" src="https://github.com/user-attachments/assets/2f1badf4-f8ff-4447-87ed-7e518e0475fe" />
   
#### 2. Launch Mastodon and import TGMM data set

   Search for mastodon in the box once you have restarted Fiji.

   <img width="503" height="281" alt="图片" src="https://github.com/user-attachments/assets/12a7c937-70f0-4bb0-bead-478bab5ba611" />
   
   Browse to the .xml file and TGMM folder as guided. For ITEC results, they can be found under `mastodon` folder. Click import button.

   <img width="421" height="441" alt="图片" src="https://github.com/user-attachments/assets/fc3d89b4-41ae-41b4-8e9e-75459811c8b1" />
   
   Then the main window of Mastodon pops up. Click bdv for visualization of the data and results. Click trackscheme for cell fate maps. Click selection table for detailed data of the spots selected.

   <img width="330" height="390" alt="图片" src="https://github.com/user-attachments/assets/9f0e4004-34cd-4e7e-b416-168a40ed2961" />

#### 3. View data through bdv, trackscheme and selection table.

   The bdv and trackscheme windows should be as follows. Use Ctrl+Shift+ScrollWheel to zoom in either window.

   <img width="347" height="250" alt="图片" src="https://github.com/user-attachments/assets/371df7a9-0025-4afc-a9da-0e4857b7b48f" /><img width="345" height="245" alt="图片" src="https://github.com/user-attachments/assets/2fb3038b-339e-4c53-a806-c161cf9d8e66" />
   
   By clicking the lock 1 in top-left corner of the two windows, a link is established between the two. Then you may choose a certain detection in the trackscheme and it will be shown in the bdv, and vice versa.

   <img width="347" height="250" alt="图片" src="https://github.com/user-attachments/assets/f1049214-c502-4aa1-983c-776a6dce6899" /><img width="352" height="250" alt="图片" src="https://github.com/user-attachments/assets/d8f1f23c-7c7b-44a0-bbe7-f3e30e5cbe46" />
   
   In bdv, scroll the wheel to scroll through z slides. Press -/+ to view through frames. Press i to apply interpolation. Press v to change overlay mode, e.g. to only show the track of the target cell.

   Select several spots in bdv or trackscheme, and their position information will be shown in the selection table window.

   <img width="578" height="385" alt="图片" src="https://github.com/user-attachments/assets/2d07780b-3662-4e7e-b608-47454eff9779" />
   
   Please refer to [Mastodon documentation](https://mastodon.readthedocs.io/en/latest/index.html) for advanced functions.



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
