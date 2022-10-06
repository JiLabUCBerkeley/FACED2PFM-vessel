Section 1: RBC flux measurement for capillaries (single-file flow) 

1. RBC flux and halftime calculation in penetrating capillaries: 
  Operation instructions: 
  a. Draw ROIs in imageJ and save the ROI files. Specify the ROI file and path, tif file and 
   path in script 'SaveImageJROI.m'. Run the script. 
  b. Run 'halfCycles.m' after filling in the required fields 
   (note 'findpeaksGM','gaussianPeakFit' and 'findDff0' are all called in this script). 
  The default settings in the scripts are for users to process the demo data (see the next section). 
  Demo data: 
  A small dataset is included in sample data\single-file, including Tif stack (20200226_20_D145.tif) 
  and zip file containing  all ROIs (20200226_20_D145_ROI.zip). 
  Expected output from demo: 
  a. Mat file generated for penetrating blood vessels, containing ROI location and raw signal inside ROI: 
        ROI_fj20200226_20_Intensity.mat (general format: ['ROI_fj',stackName(1:end-4),'_Intensity.mat'])
  b. Mat file containing all calculation results: ROI_fj20200226_20_Intensity ROI1bin1_peaks.mat

2. RBC flux measurement in horizontal capillaries (single-file flow): 
   run 'hcapillaryFlux.m'. 
   Specify the path and name for the space-time image in which RBCs appear as dark shadows. 
   Specity the frame rate and recording time. 
   An example image for flux measurement is included in sample data\single-file: 'horizontal cap_flux.tif'
   Expected output: no output files, but a visualization of detected cells on temporally varying 
   fluorescence intensity. variable 'cellCount' in the workspace is the total cell count within the 
   entire recording period (5s in the example data). 

Section 2: RBC flux measurement in large penetrating blood vessels (multi-file flow, 1D line scan).
 
Run 'multifileFlux.m' to measure RBC flux in a multi-file flow.
Specify the path and name of the image for flux measurement in the script. 
An example data is placed in 'sample data\multi-file': MHzlinescan_bin100.tif. 
Expected output after running the script on the demo data: 
  1 mat file 'cells.m' that contains a matrix with the same size as the input image. Most elements are 0
  in this matrix, except the detected cell centers that are 1. 
  1 png file: hist.png which shows the histogram of cells/ms. 
