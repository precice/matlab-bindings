# Constructing an image of Ubuntu 18.04 with MATLAB

This file describes the procedure to set an image with a running version of MATLAB, that can be used to test the MATLAB bindings.
Naturally, a MATLAB license is required for constructing the image.

Note that according to MATLAB's restrictions, **the image with working MATLAB will work only in the computer it was built in**, even though it is in a docker container inside that computer. As such, the computer set to run the test **should be the same as the one MATLAB was activated in.**

## Download MATLAB installer

First, download the MATLAB installer for linux from the mathworks webpage:

http://www.mathworks.com/downloads/web_downloads/

Be sure to put the downloaded `.zip` file in the `0-matlab` folder, and rename it to `matlab-installer.zip` before going into the next step.

## Get image with Ubuntu and MATLAB dependencies

All the commands in this file assume that the working directory is the folder '0-matlab' of the repository.

Set an image with Ubuntu 18.04 that has the required dependencies for installing MATLAB using the [Dockerfile](Dockerfile),

```
docker build -t matlab_dep .
```

## Install and Activate MATLAB

It is not possible to install MATLAB without a GUI if the license is not an administrator license. As such, one needs to install and activate MATLAB with the GUI, and after that commit the docker container as a new image. For doing this:

Run a docker container with the previously generated image, ensuring to enable X forwarding:

```
# Enable access to the X Server from other hosts
xhost +

# Run container forwarding X Server
docker run -it --rm --name matlab_install --net=host --env="DISPLAY" --volume="$HOME/.Xauthority:/root/.Xauthority:rw" matlab_dep
```

From inside the container install MATLAB:

```
cd /matlab-installer && ./install
```

And within the GUI install and activate MATLAB. Consider the following comments:
- Be sure to use the dedicated `/home/precice/MATLAB` as installation folder.
- For the installation to be quicker, one could choose only MATLAB 9.7 in the Product Selection part of the installation. 
- At the end of the installation, in the Provide user name section, make sure to choose `precice` as the Login Name, in order be able to use MATLAB while running the tests with the `precice` user.

Do not close this container until the image with MATLAB has been commited.

## Commiting image with activated MATLAB

From outside of the container, commit the modified image running these commands:

```
cnt=$(docker ps -q -f "name=matlab_install")
docker commit -m "Installed and activated MATLAB" $cnt matlab

# Disable access to the X Server from other hosts
xhost -
```

After this, the running container with MATLAB can be shut down. You can test that the container works by running it with:

```
docker run --rm -it --net=host matlab
```

And from within the container, call MATLAB with:
```
MATLAB/bin/matlab -nodisplay -nosplash -nodesktop
```