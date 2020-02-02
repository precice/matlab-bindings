# Test MATLAB Bindings

This folder contains the necessary resources for testing the MATLAB bindings. Here is a brief description of the structure of the folder:
* `0-matlab`: The testing procedure starts from an image of Ubuntu 18.04 that has a running installation of MATLAB. 
According to MATLAB's restrictions, **the image with activated MATLAB will work only in the computer it was built in**, even though it is in a docker container inside that computer. As such, the computer set to run the test **should be the same as the one MATLAB was activated in.**
If the image has to be generated again, this folder contains the description of the procedure to follow.
* `build`: Contains the Dockerfiles necessary to build preCICE and after that build and test the MATLAB bindings. **Note:** the Dockerfile for building preCICE does not run `make test` after making preCICE. As such, the installation of preCICE with MPICH is assumed to be working.
* `test.sh`: Testing procedure

One can simply specify the branch of `precice/precice` and `precice/matlab-bindings` to test in the [`test.sh`](test.sh) file and run the test from this `test` directory with: 

```
./test.sh
```