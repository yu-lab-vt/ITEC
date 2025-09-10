# Readme for ITEC


# Overview

ITEC is a high-precision, large-scale embryonic cell tracking platform dedicated to assisting developmental biologists in achieving whole-embryo lineage reconstruction and facilitating new biological discoveries. We provide the source code in MATLAB version along with a detailed user manual for reference.



# Quickstart

Running ITEC involves the following steps:

1. Code Download(link!)

1. Download the complete version of MATLAB (R2022b after is recommended)

   NOTE: When downloading MATLAB, please include at least the following toolboxes: `Image Processing Toolbox`,`Statistics and Machine Learning Toolbox`,`Parallel Computing Toolbox`.

   The download tutorial for MATLAB can be found in ***MATLAB Installation***.

1. Modify the parameter table

   This parameter table is in `.../ITEC-master/params.csv`, containing your input data path, output path, and other adjustable parameters with biological or data characteristic significance. Suggest reading ***Getting started with ITEC*** section first, and then fine-tuning the parameters based on your own data.

1. Prepare your data

   ITEC supports input in TIFF format, with each frame stored as an independent TIFF file. Your data should be stored in the *data\_path* of the parameter table.

1. Run the pipeline

   For Linux users, the following command needs to be run:
   
   ```
   cd YOUR_FOLDER/ITEC-master/src/ 
   nohup matlab -nodisplay -nosplash -nodesktop <demo.m >outinfo.txt &
   ```
   For Windows, you can open `.../ITEC-master/src/demo.m` and click *run*.

1. Visualization

The results of ITEC are saved in the path you specified. The results include the coordinates, frames, and parent-child relationships of all cells. You can use Fiji plugin Mastodon to visualize the tracking results. For a detailed format of the results, please refer to ***Getting started with ITEC***. An easy-to-use tutorial for Mastodon can be found in ***Mastodon Usage***.



# MATLAB Installation

   Our code is based on MATLAB. Most schools and research institutions offer free MATLAB. For licensing issues with MATLAB, please consult your institution.

   Please refer to the MATLAB official websites for [downloads](https://ww2.mathworks.cn/downloads/) and [installation guide](https://ww2.mathworks.cn/help/install/ug/install-products-with-internet-connection.html). Note that you may choose to install the toolboxes `Image Processing Toolbox` `Statistics and Machine Learning Toolbox` `Parallel Computing Toolbox` with MATLAB during installation, which are necessary for running ITEC.

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



# Getting started with ITEC

## Input

   The typical imput of ITEC contains the follows:

1. A 3D image set in TIFF format, with each frame stored as an independent .tif file. Please note that if your data is stored in z-slice units, you need to first store each frame's data in a .tif file before performing ITEC.
1. Parameters which ITEC apply to run.

To input your dataset and set parameters, one way is to use the ITEC graphical interface, which is guided in the next section of the tutorial. Run `ITEC.mlapp` with MATLAB to start the interface.

For remote users, you may also set those configurations in a CSV file directly. Templates of params.csv is available here(link!). Please refer to the next section for the  detailed meaning for each parameter. After configuration, you can run the `demo.m` file with MATLAB to start the algorithm. Make sure your configuration file is named as params.csv under `.../ITEC-master/src/` directory.

## Set Path and Parameters

   In the following, the corresponding name of variables in params.csv files are shown in italic in brackets.

### 1. Import Settings

   On the *Import* page of ITEC graphical interface, you can set the path to load your dataset and output results. You may also set your concerned frame range if necessary.

   <img width="538" height="225" alt="图片" src="https://github.com/user-attachments/assets/dc4bb42a-2575-40ce-b4c6-245b7f19ee10" />

   Those settings above are named as (*data\_path*), (*result\_path*), (*start\_tm*)&(*end\_tm*) in the params.csv file.

### 2. General parameters

   ----------Resolution----------

   **z-x/y ratio** (*z\_resolution*): the ratio of Z resolution OVER X/Y resolution. Z resolution refers to the distance between Z layers, in um typically. X/Y resolution refers to the real distance between neighbouring pixels. Your may derive the X/Y resolution by dividing the real length of the scope(1mm, e.g.) by the number of pixels along X direction(700, e.g.). The typical ratio should be no less than 1.

   **Cell size** (*minSize*&*maxSize*): the area range of cells along xy plane, unit in pixels. The algorithm will not detect cells beyond that range, so generally a loose range is preferred.

   **Downsampling ratio** (*xy\_downSampleScale*): the ratio of downsizing xy plane to speed up the processing. For example, a ratio of 2 will rescale a slice of 1920 \* 1080 to 960 \* 540. This ratio should be no more than z-x/y ratio to ensure detection performance.

   <img width="535" height="339" alt="图片" src="https://github.com/user-attachments/assets/a1806715-8656-4906-99b6-9e885b547f75" />

   ----------Grayscale----------

   **Intensity upper bound** (*scale\_term*): Pixels whose grayscale is above that bound will be set to that bound to ensure the contrast between pixels. You may use ImageJ to choose the upper quantile of the intensity as this bound.

   **Intensity lower bound** (*clipping*): Similar to the upper bound, the algorithm will reset pixels below that bound to 0 and further enhance contrast. For generally dark data, 0 should be fine, while it can be increased when the background noise is generally high.

   **Background intensity** (*bgIntensity*): a general threshold of the grayscale of the background compared to the cells. Cells with intensity below that threshold won’t be detected. You may use ImageJ to help you set an approximate value.

   <img width="540" height="336" alt="图片" src="https://github.com/user-attachments/assets/b88192cf-86c0-49c7-9b8e-588d89303454" />

   ----------Smoothing----------

   **Filter factor** (*filter\_sigma*): the intensity of the Gaussian filter used to highlight signals. You can increase it when background noise is high, or to get more conservative  segmentation. Usual range is [1, 5].

### 3. Segmentation parameters

   **Save visualization results** (*visualization*): flags whether to save the visualized results. You may choose no to speed up the process.

   **smFactor** (*smFactor*): can increase it to prevent over-segmentation. Usual range is [0.3, 2].

   ----------Advanced parameters----------

   **curvesThres** (*curvesThres*): The threshold of detecting seeds for core regions, usually -5. Can be increased to up to -3 to encourage cellular core detection.

   **foreThres** (*foreThres*): The threshold of detecting boundaries, usually +3. Can be lowered to down to 1 to encourage boundary detection.

   **Intensity difference** (*diffIntensity*): Usually 0. Can increase it to get better segmentation result given that the grayscale difference between the cells and background is distinct.

   <img width="584" height="345" alt="图片" src="https://github.com/user-attachments/assets/e170bbf1-7346-4527-92a7-520d53fa8b2d" />

### 4. Tracking parameters

   **maxIter** (*maxIter*): The max number of iteration steps of error correction. Usually 3/4 is enough for convergence. Can increase it if results vary much with the iterations.

   **division factor** (*division\_thres*): The intensity of detecting divisions. Can increase it to detect more divisions. Usual range is [0.9, 1].

   ----------Advanced parameters---------

   **Save augmented seg. Results** (*saveAllResults*): flags whether to save the segmentation results after error-correction-based tracking. Note that the error correction process may change the previous segmentation result to achieve better linkage.

   **Use motion flow estimation** (*useMotionFlow*): flags whether to apply motion flow methods during registration. The use of motion flow often achieves better results.

   **Max distance** (*max\_dist*): a rough bound of the maximum displacement in pixels from frame t to t+1 (e.g. in division case, the displacement from the division spot to the location of a child in the next frame). It is used to exclude too far transition between frames. Usually 50 is fine. You may decrease it if you find some unreasonable transitions.

   <img width="590" height="435" alt="图片" src="https://github.com/user-attachments/assets/d80d99e9-82c3-4a32-ba15-b561e4618656" />
   
## Start tracking, check output and re-tune parameters

   After you have set all the parameters, turn to the *Start Tracking* page. Click *save parameters* button to save path and parameters above. Then click *run* button to start ITEC!

   <img width="603" height="435" alt="图片" src="https://github.com/user-attachments/assets/ec642505-31ff-4f24-9025-f0997f4ae4df" />

   The output of ITEC contains the follows: 

1. A standard CSV file, which succinctly contains the unique ID, XYZ coordinates, frames, and the parent ID associated with the previous frame of all cells.

1. Data that can be directly used for Mastodon visualization, including accompanying h5/xml and tgmm for recording tracking results. Regarding the use of Mastodon, you can refer to ***Mastodon usage***.

You can find all of the output in your output path. If you are not satisfied with the results, you may turn to the former page to adjust the parameters and run again. Should you have any difficulties tuning the parameters, please refer to ***FAQ*** using the link on the *Contact us* page or contact us at [github](https://github.com/yu-lab-vt/ITEC).

## Import parameters directly next time (Optional)

   To import your .csv of parameters directly, click ‘I want to import parameters directly from a parameter file’ on the *import* page, and set the path to load the file. Path and parameters on the pages will be loaded automatically.

   <img width="612" height="375" alt="图片" src="https://github.com/user-attachments/assets/6814b2ed-c3e4-421d-83d9-54dcf02c31f9" />

# Mastodon usage

   We have provided several examples for users to refer to. 

### 1. Start Fiji/ImageJ and get Mastodon.
   Start the updater.

   <img width="381" height="269" alt="图片" src="https://github.com/user-attachments/assets/b9b1095b-ac42-4bcc-bff2-0786a834e41c" />

   Click on the Manage update sites button, and search for Mastodon in the site management dialog. Select all the three sites by Mastodon. Then click Apply and Close and Apply Changes in turn. Restart ImageJ as guided.

   <img width="389" height="300" alt="图片" src="https://github.com/user-attachments/assets/2f1badf4-f8ff-4447-87ed-7e518e0475fe" />
   
### 2. Launch Mastodon and import TGMM data set

   Search for mastodon in the box once you have restarted Fiji.

   <img width="503" height="281" alt="图片" src="https://github.com/user-attachments/assets/12a7c937-70f0-4bb0-bead-478bab5ba611" />
   
   Browse to the .xml file and TGMM folder as guided. For ITEC results, they can be found under `mastodon` folder. Click import button.

   <img width="421" height="441" alt="图片" src="https://github.com/user-attachments/assets/fc3d89b4-41ae-41b4-8e9e-75459811c8b1" />
   
   Then the main window of Mastodon pops up. Click bdv for visualization of the data and results. Click trackscheme for cell fate maps. Click selection table for detailed data of the spots selected.

   <img width="330" height="390" alt="图片" src="https://github.com/user-attachments/assets/9f0e4004-34cd-4e7e-b416-168a40ed2961" />

### 3. View data through bdv, trackscheme and selection table.

   The bdv and trackscheme windows should be as follows. Use Ctrl+Shift+ScrollWheel to zoom in either window.

   <img width="347" height="250" alt="图片" src="https://github.com/user-attachments/assets/371df7a9-0025-4afc-a9da-0e4857b7b48f" /><img width="345" height="245" alt="图片" src="https://github.com/user-attachments/assets/2fb3038b-339e-4c53-a806-c161cf9d8e66" />
   
   By clicking the lock 1 in top-left corner of the two windows, a link is established between the two. Then you may choose a certain detection in the trackscheme and it will be shown in the bdv, and vice versa.

   <img width="347" height="250" alt="图片" src="https://github.com/user-attachments/assets/f1049214-c502-4aa1-983c-776a6dce6899" /><img width="352" height="250" alt="图片" src="https://github.com/user-attachments/assets/d8f1f23c-7c7b-44a0-bbe7-f3e30e5cbe46" />
   
   In bdv, scroll the wheel to scroll through z slides. Press -/+ to view through frames. Press i to apply interpolation. Press v to change overlay mode, e.g. to only show the track of the target cell.

   Select several spots in bdv or trackscheme, and their position information will be shown in the selection table window.

   <img width="578" height="385" alt="图片" src="https://github.com/user-attachments/assets/2d07780b-3662-4e7e-b608-47454eff9779" />
   
   Please refer to [Mastodon documentation](https://mastodon.readthedocs.io/en/latest/index.html) for advanced functions.



# FAQ

### 1. I found a lot of cells over-segmented in the result. How can I tune the params?

   This problem may result from distinct noise or too intensive segmentation. Accordingly, you may tune up the Filter factor in *Smooting* section, or the smFactor  in *Segmentation* section.

### 2. I found a lot of cells under-segmented in the result. How can I tune the params?

   In *Smoothing* section, make sure your Filter factor is not set too high as it may fuse cell boundaries. Also, you may tune down the smFactor in *Segmentation* section and see if it works.

### 3. I want to track the cells within a certain size range. What should I do?

   In *Resolution* section, you can adjust the cell size parameters (max size & min size) to achieve that. The algorithm will exclude cells beyond that range. For example, if you do not want the small cells, you may tune up the min size a little bit to get rid of them.

### 4. I found part of the detections that ITEC provided seem not to be true cells. How can I tune the params?

   Most of the time this situation results from a too-low Background intensity in *Grayscale* section. Try tune it up to a proper level to distinguish the cells. You may further check other *Grayscale* parameters if it does not work.

### 5. I found many cells missing, or fragmented tracks. How can I tune the params?

   You may first check if your *Grayscale* parameters are set properly. As ITEC remaps the intensity based on upper/lower bounds during pre-processing, a smaller range is better to show the contrast in between. Also make sure the Background intensity is set appropriately within the bounds, not too high. 

   On top of that, you may tune up the curveThres a little bit in *advanced parameters for segmentation*. Framented track may also result from a low Max distance setting in *advanced parameters for tracking*,with data of compromised time resolution.

### 6. I found ITEC detected few/too many divisions. How can I tune the params?

   Division detection is mainly controlled by the division factor in *Tracking* section. Try tune it up a bit to encourage more detections of divsion, and vice versa. If the time resolution of your data is compromised, you may tune up the Max distance in *advanced parameters for tracking* to allow more vibrant transitions.

### 7. I found ITEC takes a long time at every stage. Is there anything wrong?

   ITEC leverages parallel computing for acceleration, so make sure you have install the parallel computing toolbox on MATLAB before processing. Also, try to crop the raw data into ceratin region of interest before importing it into ITEC.

   As for parameters, for large scale data with good z-x/y ratios, you can set the Downsampling ratio in *Resolution* section above 1 to further accelerate the process. Besides, make sure your maxIter in *Tracking* section is not too large. 



# Theory Support

   Our paper can be found here(link!). If you have any questions about the method, please contact <yug@tsinghua.edu.cn>



# Citing
