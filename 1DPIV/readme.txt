PIV method 
File naming example and expected output: 
Note: In the example below, the 20200226 part in the file name is not neccessary, other parts are ideal for 
directly running the codes without a problem. 
tif stack: 20200226_01_D600.tif (D600 here means the data was taken at 600 um below skull) 
Temporal-averaged morphology image: 20200226_01_D600_sum.tif
ImageJROI file: 20200226_01_D600_kymoROI.roi for single ROI,or .zip for multiple ROIs saved in a single 
                file
                Note: Please use either 'Straight line' or 'Freehand line' to draw line ROIs. Other ROIs
                are not supported at this stage and will lead to error. 
Kymographs: 20200226_01_D600_kymoROI01.tif (note the file is automatically saved in this name format if 
            the kymograph is generated using the code 'getKymo.m'
PIV output mat file: velocity_20200226_01_D600ROI01_avg50skip1shift2_001-143 (numbers after 'avg', 'skip', 
                   and shift are settings in 'LSPIV_parallel'. 001-143 is the processing range in the
                   kymograph (e.g. if the kymograph is 200 pixels wide, then 001-143 means only the first
                   143 lines are included in flow velocity calculation, and the rest is cropped out). 


PIV method
1. If the original tif data is in 2D, first draw the line ROIs in image J, save the ROI file in the name
   format described in section 2. 
   Then run 'getKymo.m'. Remember to fill in the file path and required fields in the script to specify 
   the tif stack and imageJ ROI file to process. 
   Skip this step if you are starting from kymographs directly. 
2. Run 'LSPIV_parallel'. Remember to fill in the required fields. 
   The file will output a mat file as described in section 2. 
   Note: vesselAngleD is called in the script 'LSPIV_parallel' if matched imageJ ROIs can be found for the
         kymograph being processed (i.e. in the case where 2D full-frame hemodynamic imaging was performed
         and step a was gone through). If you start from the kymographs directly, i.e. there is no matched
         full-frame stacks for the kymograph, LSPIV_parallel will display an error message box saying 'no 
         ROI can be found' (this can also occur if you failed to follow the naming rules or gave the wrong 
         path in the script) and proceed to later-on steps. You can still calculate vessel diameter by 
         running vesselAngleD.m seperately (see step c for instructions).
3. (optional) To run the vesselAngleD script independently (i.e. without kymographs), you will have to 
   draw a line ROI along the length of the vessel of interest in the morphology image and save the imageJ 
   ROIs following instructions in section 2. 
 
Demo data: 
A small 2D dataset '20200302_47_D430.tif' is included in sample data\PIV to demonstrate the processing 
starting from step a in section 3 part 1. 20200302_47_D430_sum.tif is the temporally summed morphology
image of the blood vessel cross-sections. 20200302_47_D430_kymoROI.zip contains the imageJ ROIs. 

A kymograph 20200226_16_D360_kymoROI01.tif is included as well to guide processing starting from 
kymographs directly 




