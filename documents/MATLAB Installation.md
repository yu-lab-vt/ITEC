## MATLAB Installation


   Please refer to the MATLAB official websites for [download](https://ww2.mathworks.cn/downloads/) and [installation guide](https://ww2.mathworks.cn/help/install/ug/install-products-with-internet-connection.html). Many schools and research institutions offer free MATLAB. For licensing issues with MATLAB, please consult your institution. 
   
  **Note: the toolboxes `Image Processing Toolbox` `Statistics and Machine Learning Toolbox` `Parallel Computing Toolbox` need to be installed during MATLAB installation.**

   If you are using a server without a graphical interface, you can install MATLAB as follows:

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

