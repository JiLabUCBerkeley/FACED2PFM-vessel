System requirements and installation guide
To run the codes, no other software other than MATLAB is required. Please follow instructions on 
https://www.mathworks.com/products/get-matlab.html to install MATLAB. Any operating systems compatible
with MATLAB will be able to run the codes. 
MATLAB signal processing toolbox and parallel computing toolbox are required to run the codes.
* Software like Microsoft Visual Studio may be required to read and edit C++ scripts in the SIFT flow 
  pipeline, but not required to only run the code. 

The software was tested on windows 10, MATLAB R2021a. 

There are three pipelines included in this folder. Each pipeline has a distinct subpath. 
1. 1DPIV: PIV method for velocity measurements from kymographs of horizontally oriented blood vessels 
2. flux: Flux and halftime calculation for vertically oriented capillaries with a single file flow, and
   vertically oriented arteries and veins with a multi-file flow.  
3. SIFT flow: 2D PIV analysis for horizontally oriented blood vessels with a multi-file flow. 

to run the pipelines, follow instructions on 'readme.txt' under each pipeline folder. 

