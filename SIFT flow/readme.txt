The pipeline was tested on windows 10 (64-bit operating system, x64-based processor),
in MATLAB 2021a. 

File description: 
MATLAB scripts in the main folder: 
  'SIFTflow_demo.m' is the main script that calls 'SIFTflowc2f.m' in the main folder. 
Sub-folders: 
  'mexDenseSIFT' and 'mexDiscreteFlow': contains cpp and mex files required for SIFT 
  flow calculation. 
  'sample data' contains 1 example dataset with a polygon ROI sketching the 
  'other functions' contains other scripts downloaded with the SIFT flow package but
   not called by 'SIFTflow_demo.m'. 
Notes: 
  All c++ files (.cpp and .h files) in this package were directly downloaded from: 
  https://people.csail.mit.edu/celiu/SIFTflow/
  except the following files: 
  in 'mexDenseSIFT': Vector.cpp, Matrix.cpp and image.h 
  in 'mexDiscreteFlow': Image.h and mexDiscreteFlow.cpp
  In the above scripts, 'int' was changed to 'mwSize' so that the files can be complied
  in 64-bit MATLAB under a 64-bit system. 


Operation instructions: 
1. Run 'SIFTflow_demo.m' 
   Note:  'change folder' option is recommended when Matlab window '...SIFTflow_demo.m
   is not found in the current folder on the MATLAB path' prompts out.  
   If you choose 'add to path' option instead, change 'mainPath' variable in the script 
   to the directory that contains the demo script and the three folders below: 
    'mexDenseSIFT', 'mexDiscreteFlow', and 'sample data'. 
   If no errors occur, no further actions are required. If you encounter compiling 
   errors, proceed to step 2 and 3 to re-compile all .cpp and .h files. 
   DO NOT skip step 1 before doing step 2 and 3, even if you would like to re-compile
   all the c++ files. Doing step 1 properly will ensure the subpaths 'mexDenseSIFT' and
   'mexDiscreteFlow'to be added into MATLAB search directory, which is required for step
   2 and 3. 
2. Run 'mex mexDenseSIFT.cpp Matrix.cpp Vector.cpp' in MATLAB. 
3. Run 'mex mexDiscreteFlow.cpp BPFlow.cpp Stochastic.cpp' in MATLAB. 
4. If you encounter any errors in step 2 and 3, refer to 'readme.txt' files provided by 
   the orignial developer of SIFT flow in 'mexDenseSIFT' and 'mexDiscreteFlow' subpaths 
   (there is a readme.txt file in each of the two folders). 

Expected output from the demo: 
  One sample dataset: 'multi-file flow_venule.tif' is included in the 'sample data' subpath.
  'SIFTflow_demo.m' will create a subfolder in 'sample data', with the same name as the 
tif file, in this case: multi-file flow_venule. The 'multi-file flow_venule' folder should 
have 4 expected outputs: 
   1 mat file that contains all processing results: 
flow_multi-file flow_venule_upsampling2.00.mat'
   1 avi file that shows the velocity map updated at the orignial frame rate of the input 
data (1kHz in this case)
   1 png file that shows the mean velocity map with a labeled color bar
   1 tif file that shows the color-coded mean velocity map without the color bar. 

