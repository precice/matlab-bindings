# MATLAB bindings

These bindings allow to use preCICE with MATLAB based on the C++ MEX and C data API. They are still in an experimental state, so please utilize them with care. Any feedback is welcome.

Note that the first three digits of the version number of the bindings indicate the preCICE version that the bindings support. The last digit represents the version of the bindings. Example: `v2.0.0.1` of the bindings represents version `1` of the bindings which is compatible with preCICE `v2.0.0`.

## Requirements

MATLAB R2018a or later is required. The bindings were tested on R2018b, R2019a and R2019b.

## Restrictions

- An issue causes MATLAB to crash upon SolverInterface initialization if precice was compiled with openmpi. This issue can be resolved by installing openmpi from source using the option `-disable-dlopen`. For reference, see e.g. [here](https://stackoverflow.com/questions/26901663/error-when-running-openmpi-based-library). Alternatively, the user can switch to a different MPI implementation, e.g. MPICH (other implementations were not tested). Note that for [using a different MPI implementation](https://github.com/precice/precice/wiki/Building:-Using-CMake#build-precice-using-non-default-mpi-implementation) one has to specify the alternative implementation while building preCICE.
- Currently, only one instance of the `SolverInterface` class can exist at the same time in a single MATLAB instance. If the user wishes to couple multiple participants based on MATLAB, he is supposed to start them in different MATLAB instances. If, for some reason, the user needs multiple instances of `SolverInterface`, he should use the OOP variant (Multiple instances of `SolverInterfaceOOP` can exist at the same time).
- There is a known bug, if the `SolverInterface` destructor is called. For a possible workaround refer to https://github.com/precice/precice/issues/378. 

## Compilation

The MATLAB script `compile_matlab_bindings_for_precice.m` located in this folder compiles the bindings. Simply running it from MATLAB should do.

In some cases, MATLAB's own `libstdc++` library may be an old version, which leads an error while compiling the bindings, of the kind "version 'CXXABI_1.3.11' not found". In this case, one can set MATLAB to use another version of `libstdc++` with the `LD_PRELOAD` variable (see [here](https://alexxunxu.wordpress.com/2018/01/15/version-cxxabi_1-3-8-not-found/) for further reference). For example, for using the system's default `libstdc++`, one can open MATLAB with the following command:
```
LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6 matlab
```

The script uses `pkg-config` to determine the necessary flags. If `pkg-config` is unable to find the flags, the script will throw an error. Please refer to the [Linking to preCICE](https://github.com/precice/precice/wiki/Linking-to-preCICE) page in the preCICE wiki for details regarding `pkg-config`.

If using the script fails for some reason, please let us know.

## Add to path

To use the bindings, you have to add this folder (e.g. `/home/user/matlab-bindings`) to your MATLAB path using [`addpath`](https://de.mathworks.com/help/matlab/ref/addpath.html?searchHighlight=addpath&s_tid=doc_srchtitle). Adding this folder alone is sufficient (you don't have to use `genpath`). You can let MATLAB do this at startup by adding the respective line to your `startup.m`, see [here](https://de.mathworks.com/help/matlab/matlab_env/add-folders-to-matlab-search-path-at-startup.html).

## Usage

The API introduces a MATLAB wrapper class for the `SolverInterface` class and a namespace for the preCICE constants. They are accessible in MATLAB as `precice.SolverInterface` and `precice.constants` respectively.

The function syntax is mostly identical to the syntax of the C++ API. The following things should be noted:
- C++ `int`s correspond to MATLAB `int32`s.
- Wherever the C++ API expects pointers, the MATLAB API expects a matrix/vector instead. If the user wants to pass vector data (e.g. vertex coordinates) for multiple vertices, the shape of the corresponding matrix must be `[dim numVertices]`, where `dim` is the problem dimension. Thus, each **column** must correspond to a vertex, and each line must correspond to a coordinate - **not** vice versa. Users should try to respect this in their MATLAB code from the start, because transposing can be costly for huge matrices.
- There are two changes in the input arguments for the MATLAB API with respect to the C++ API: 
    - Output arguments which are pointers passed as input arguments to the C++ preCICE API are replaced by output matrices.
    - As the MATLAB API receives matrices/vectors instead of pointers, the size (e.g. number of vertices) of the arrays is not an input argument, but instead it is inferred from the array.

As an example, the C++ API function
```
readBlockScalarData(int dataID, int size, const int *valueIndices, double *values)
```
is found in the MATLAB bindings as
```
values = readBlockScalarData(dataID, valueIndices)
```

## Out of process variant

The C++ MEX API supports [out of process execution](https://de.mathworks.com/help/matlab/matlab_external/out-of-process-execution-of-c-mex-functions.html) of MEX functions. This feature is implemented in the class `precice.SolverInterfaceOOP`. This class works exactly like `precice.SolverInterface`. Internally, however, the gateway function that calls the preCICE routines is run on a `mexHost` object.
This has the following advantages:
- Multiple instances of `SolverInterfaceOOP` can exist at the same time.
- If the gateway function crashes, then MATLAB will not crash. Only the mexHost object will crash.
However, using the OOP variant is **significantly** slower than the normal in process

# Troubleshooting

## `libprecice.so` cannot be found

```
Invalid MEX-file 'SOMEPATH/matlab-bindings/+precice/@SolverInterface/private/preciceGateway.mexa64':
libprecice.so.2: cannot open shared object file: No such file or directory.
```

Tells you that the MATLAB bindings cannot find the C++ library preCICE. Make sure that you [installed preCICE correctly](https://github.com/precice/precice/wiki/Building:-Using-CMake#checking-your-installation). 

You can also run `pkg-config --cflags --libs libprecice` to see whether the paths provided by `pkg-config` point to the correct place. Example output, if everything is correct and you installed preCICE via `sudo make install`:

```
$ pkg-config --cflags --libs libprecice
-I/usr/local/include -L/usr/local/lib -lprecice
```

If everything until this point looks good and you are still facing problems and you installed preCICE to a custom location using `CMAKE_INSTALL_PREFIX`, MATLAB might not be able to find `libprecice.so`, since it is not discoverable. Please add the location of `libprecice.so` (see `pkg-config --libs-only-L libprecice`, without the `-L`) to your `LD_LIBRARY_PATH`. For further instructions refer to the [MATLAB documentation](https://de.mathworks.com/help/matlab/matlab_external/set-run-time-library-path-on-linux-systems.html).

# Contributors

* [Dominik Volland](https://github.com/Dominanz) contributed first working prototype in [PR #494 on `precice/precice`](https://github.com/precice/precice/pull/494)
* [Gilberto Lem](https://github.com/gilbertolem) integrated bindings into existing infrastructure of preCICE in [PR #580 on `precice/precice`](https://github.com/precice/precice/pull/580)
* [Benjamin Rüth](https://github.com/BenjaminRueth)
* [Frédéric Simonis](https://github.com/fsimonis)
