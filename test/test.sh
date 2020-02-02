### Choose branches ###

# Branch of `github.com/precice/precice` to test
export precice_branch=develop

# Branch of `github.com/precice/matlab-bindings` to test
export bindings_branch=develop

### Testing ###

# Build preCICE with MPICH on the image of Ubuntu+MATLAB
docker build -t precice_mpich -f build/Dockerfile.1_precice_mpich --build-arg branch=$precice_branch . && \

# Build MATLAB bindings on the image with preCICE with MPICH
docker build --network=host -t bindings -f build/Dockerfile.2_bindings --build-arg branch=$bindings_branch .