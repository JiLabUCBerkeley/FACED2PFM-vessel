# Blood flow analysis from _in vivo_ fluorescence imaging

## Citation:  
G. Meng et al., Ultrafast two-photon fluorescence imaging of cerebral blood circulation in the mouse brain in vivo. 
Proceedings of the National Academy of Sciences 119, e2117346119 (2022).

Please cite the above publication if you use the code in this repository. This README file was created by Dr. Guanghan Meng in April, 2022

## Introduction 
Characterizing blood flow by tracking individual red blood cells as they move through vessels is essential for understanding vascular function. With high spatial resolution, two-photon fluorescence microscopy is the method of choice for imaging blood flow at the cellular level. This software package is designed to calculate flow speed from 1D kymographs and 2D full-frame videos with individual blood cell resolvable from the original recording. 
Exmample 1D kymographs (space-time images) and flow velocity analysis using 1D PIV pipeline: 
![image](https://user-images.githubusercontent.com/20729322/194419400-4b90b092-05f6-4b31-980d-42b18771f6ea.png)

![image](https://user-images.githubusercontent.com/20729322/194419638-5ed29fa5-be5e-493e-91fa-900d50b7211a.png)
Example 2D flow analysis directly read out from kHz recording using SIFT flow pipeline: 

https://user-images.githubusercontent.com/20729322/194419883-40dfc59f-0e88-477b-bc3c-2fc9b8af103e.mp4

https://user-images.githubusercontent.com/20729322/194419870-28c6e42f-fb7c-4cd5-9a7e-81f696ab841f.mp4


## Genral information
There are three pipelines included in this folder. Each pipeline has a distinct subpath. 
1. 1DPIV: PIV method for velocity measurements from kymographs of horizontally oriented blood vessels 
2. flux: Flux and halftime calculation for vertically oriented capillaries with a single file flow, and vertically oriented arteries and veins with a multi-file flow. 
3. SIFT flow: 2D PIV analysis for horizontally oriented blood vessels with a multi-file flow. 
The software was tested on a windows 10 machine, MATLAB version: R2021a. 
#### To run the pipelines, follow system requirement & installation guide below and instructions in 'readme' under each pipeline's subfolder. 

## System requirements and installation guide
To run the codes, no other software other than MATLAB is required. Please follow instructions on https://www.mathworks.com/products/get-matlab.html to install MATLAB. Any operating systems compatible with MATLAB will be able to run the codes. 
MATLAB signal processing toolbox and parallel computing toolbox are required to run the codes.
* Software like Microsoft Visual Studio may be required to read and edit C++ scripts in the SIFT flow pipeline, but not required to only run the code. 




