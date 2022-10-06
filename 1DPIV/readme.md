# 1D Particle image velocimetry (PIV) analysis for kymographs
## Section 1: Rules & examples of file naming, and expected output: 
This method of flow velocity calculation can start from a kymograph or a full-frame stack. If the original input is a full-frame stack, line-shape ROIs need to be first drawn in Fiji in order to generate kymographs.
Note: In the example below, the 20200226 part in the file name is not neccessary, other parts are required for directly running the codes without a problem. 
### a. tiff stack:
Example: 20200226_01_D600.tif; Note: D600 here means the data was taken at 600 um below skull. 
This tiff stack is required only if you need to generate kymographs from full-frame recording. 
### b. Time-averaged morphology image
Example: 20200226_01_D600_sum.tif
Note: the file is required if one wants to calculate the orientation and diameter of the blood vessel using input Fiji line ROIs. The file is automatically saved if kymographs for the tiff stack in 'a' are generated using the code 'getKymo.m'
### c. ImageJ/Fiji ROI file: 
Example: 20200226_01_D600_kymoROI.roi for single ROI,or .zip for multiple ROIs saved in a single file
   #### Note: Please use either 'Straight line' or 'Freehand line' to draw line ROIs. Other types of ROIs are not supported at this stage and will lead to error. 
### d. Kymographs: 
Example: 20200226_01_D600_kymoROI01.tif 
If kymographs are directly obtained from line scanning, files a - c are not required.  Otherwise, b and d will be generated after running 'getKymo.m'
### e. PIV output mat file: 
Example: velocity_20200226_01_D600ROI01_avg50skip1shift2_001-143 
numbers after 'avg', 'skip', and "shift" are settings in 'LSPIV_parallel.m'. 001-143 is the processing range in the kymograph (e.g. if the kymograph is 200 pixels wide, then 001-143 means only the first 143 lines are included in flow velocity calculation, and the rest is cropped out). 
This is the output file that contains all the calculation results output from 'LSPIV_parallel.m'

## Section 2: step-by-step instructions for running the code
Before start, make sure to alter the file name (either the tiff stack or the kymograph) following the rules in section 1. 
### 1. Draw and save line ROIs in Fiji. 
   If the original tif data is in 2D, first draw the line ROIs in image J, save the ROI file in the name
   format described in section 2. 
   Only 'Freehand line' and 'Straight line' tools in Fiji are supported at this point. Other formats of ROIs are not compatible. 
   The ROI file has to be in '.roi' or '.zip' format. Make sure the file name follows the instructions in section 1. 
   If you want to start the analysis directly from kymographs, skip steps 1 & 2 and proceed to step 3. 
### 2. Generate kymographs 
   Fill in the file path and required fields in 'getKymo.m' to specify the tif stack and imageJ ROI file to process, and run the script. 
   Skip this step if you are starting from existing kymographs. 
### 3. Run the main script to read out blood flow velocity from kymographs 
   Fill in the required fields in 'LSPIV_parallel' and run the script.
   The file will output a mat file as described in section 1e. 
   Note: vesselAngleD is called in the script 'LSPIV_parallel' if matched imageJ ROIs can be found for the kymograph being processed (i.e. in the case where 2D full   frame hemodynamic imaging was performed and step a was gone through). If you start from the kymographs directly and there is no matched full-frame stacks for the      kymograph, LSPIV_parallel will display an error message box saying 'no ROI can be found' (this can also occur if you failed to follow the naming rules or gave the      wrong path in the script) and proceed to the later steps. You can still calculate vessel diameter by running vesselAngleD.m seperately (see step 4 for                  instructions). If the ROI file can be found but there is no morphology file, the algorithm will also have a error message window and exit vessel diameter and orientation calculation. 
   If you are re-processing kymographs generated from step 2 using different velocity calculation parameters, as long as all files in Section 1a-d are still in the current path, no need to do redo steps 1-2. 
### 4. (optional) Calculate the vessel diameter and pixel size separtely
   To run the vesselAngleD script independently (i.e. without kymographs), you will have to draw a line ROI along the length of the vessel of interest in the morphology image and save the imageJ ROIs following instructions in step 1. 
 
## Section 3: Demo data in the 'sample data' folder
### 1. full-frame stack as raw input: 
A small dataset '20200302_47_D430.tif' is included in 'sample data' to demonstrate steps 1 - 3 in section 2. 
20200302_47_D430_sum.tif is the time-summed morphology image of the blood vessel cross-sections. 
20200302_47_D430_kymoROI.zip contains the imageJ ROIs. 
### 2. kymographs as raw input
A kymograph 20200226_16_D360_kymoROI01.tif is included as well to guide processing starting from 
kymographs directly, section 2 step 3 only
