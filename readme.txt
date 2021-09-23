System requirements and installation guide
To run the codes, no other software other than MATLAB is required. Please follow instructions on 
https://www.mathworks.com/products/get-matlab.html to install MATLAB. Any operating systems compatible
with MATLAB will be able to run the codes. 
MATLAB signal processing toolbox and parallel computing toolbox are required to run the codes.

The software was tested on windows 10, MATLAB R2021a or MATLAB R2019b. 
No additional installation steps are required. Just make sure to place all scripts involved in the 
working directory or in a folder added to the MATLAB search path. 

Section 1: overview

The codes contain two pipelines: 
1. PIV method for velocity measurements from kymographs of horizontally oriented blood vessels 
2. Flux and halftime calculation for vertically oriented blood vessels. 



Section 2: file naming example and expected output

1. PIV method: 
Note: In the example below, the 20200226 part in the file name is not neccessary, other parts are ideal for 
directly running the codes without a problem. 
tif stack: 20200226_01_D600.tif (D600 here means the data was taken at 600 um below skull) 
Temporal-averaged morphology image: 20200226_01_D600_sum.tif
ImageJROI file: 20200226_01_D600_kymoROI.roi for single ROI,or .zip for multiple ROIs saved in a single 
                file
Kymographs: 20200226_01_D600_kymoROI01.tif (note the file is automatically saved in this name format if 
            the kymograph is generated using the code 'getKymo.m'
PIV output mat file: velocity_20200226_01_D600ROI01_avg50skip1shift2_001-143 (numbers after 'avg', 'skip', 
                   and shift are settings in 'LSPIV_parallel'. 001-143 is the processing range in the
                   kymograph (e.g. if the kymograph is 200 pixels wide, then 001-143 means only the first
                   143 lines are included in flow velocity calculation, and the rest is cropped out). 
2. Flux and halftime calculation: 
There are no requirements for naming the stack or the ROI. Below is just an example: 
Mat file generated for penetrating blood vessels, containing ROI location and raw signal inside ROI: 
        ROI_fj20200226_20_Intensity.mat (general format: ['ROI_fj',stackName(1:end-4),'_Intensity.mat'])
Mat file containing all calculation results: ROI_fj20200226_20_Intensity ROI1bin1_peaks.mat



Section 3: Operation instructions

1. PIV method
a. If the original tif data is in 2D, first draw the line ROIs in image J, save the ROI file in the name
   format described in section 2. 
   Then run 'getKymo.m'. Remember to fill in the file path and required fields in the script to specify 
   the tif stack and imageJ ROI file to process. 
   Skip this step if you are starting from kymographs directly. 
b. Run 'LSPIV_parallel'. Remember to fill in the required fields. 
   The file will output a mat file as described in section 2. 
   Note: vesselAngleD is called in the script 'LSPIV_parallel' if matched imageJ ROIs can be found for the
         kymograph being processed (i.e. in the case where 2D full-frame hemodynamic imaging was performed
         and step a was gone through). If you start from the kymographs directly, i.e. there is no matched
         full-frame stacks for the kymograph, LSPIV_parallel will display an error message box saying 'no 
         ROI can be found' (this can also occur if you failed to follow the naming rules or gave the wrong 
         path in the script) and proceed to later-on steps. You can still calculate vessel diameter by 
         running vesselAngleD.m seperately (see step c for instructions).
c. (optional) To run the vesselAngleD script independently (i.e. without kymographs), you will have to 
   draw a line ROI along the length of the vessel of interest in the morphology image and save the imageJ 
   ROIs following instructions in section 2. 
 
2. Cell flux and halftime calculation in penetrating blood vessels
a. Draw ROIs in imageJ and save the ROI files. Specify the ROI file and path, tif file and path in script 
   'SaveImageJROI.m'. Run the script. 
b. Run 'halfCycles.m' after filling in the required fields 
   (note 'findpeaksGM','gaussianPeakFit' and 'findDff0' are all called in this script). 
The default settings in the scripts are for users to process the demo data (see the next section). 

Section 4: Demo data 

1. PIV method
A small 2D dataset '20200302_47_D430.tif' is included in sample data\PIV to demonstrate the processing 
starting from step a in section 3 part 1. 20200302_47_D430_sum.tif is the temporally summed morphology
image of the blood vessel cross-sections. 20200302_47_D430_kymoROI.zip contains the imageJ ROIs. 

A kymograph 20200226_16_D360_kymoROI01.tif is included as well to guide processing starting from 
kymographs directly 

2. cell flux and half cycle: 
A small dataset is included in sample data\FluxHC, including Tif stack and zip file containing all ROIs. 



