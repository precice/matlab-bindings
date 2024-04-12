# MATLAB bindings

These bindings allow to use preCICE with MATLAB based on the C++ MEX and C data API. They are still in an experimental state, so please utilize them with care. Any feedback is welcome.

Note that the first two digits of the version number of the bindings indicate the major and minor version of the preCICE version that the bindings support. The last digit represents the version of the bindings. Example: `v3.1.0` and `v3.1.1` of the bindings represent versions `0` and `1` of the bindings that are compatible with preCICE `v3.1.x`. Note that this versioning scheme was introduced from bindings `v3.1.0`, which is different than the [old versioning scheme](#old-versioning-scheme).

## Requirements

MATLAB R2018a or later is required. The bindings are actively tested on versions R2023b, R2023a, R2022b, R2022a, and R2021b.

## Restrictions

- An issue causes MATLAB to crash upon SolverInterface initialization if precice was compiled with openmpi. This issue can be resolved by installing openmpi from source using the option `-disable-dlopen`. For reference, see e.g. [here](https://stackoverflow.com/questions/26901663/error-when-running-openmpi-based-library). Alternatively, the user can switch to a different MPI implementation, e.g. MPICH (other implementations were not tested). Note that for [using a different MPI implementation](https://precice.org/installation-source-advanced.html#mpi---build-precice-using-non-default-mpi-implementation) one has to specify the alternative implementation while building preCICE. For more information on this issue, please refer to https://github.com/precice/matlab-bindings/issues/19.
- Currently, only one instance of the `SolverInterface` class can exist at the same time in a single MATLAB instance. If the user wishes to couple multiple participants based on MATLAB, he is supposed to start them in different MATLAB instances. If, for some reason, the user needs multiple instances of `SolverInterface`, he should use the OOP variant (Multiple instances of `SolverInterfaceOOP` can exist at the same time).
- There is a known bug, if the `SolverInterface` destructor is called. For a possible workaround refer to https://github.com/precice/precice/issues/378. This issue is tracked in https://github.com/precice/matlab-bindings/issues/28.

## Compilation

The MATLAB script `compile_matlab_bindings_for_precice.m` located in this folder compiles the bindings. Simply running it from MATLAB should do.

In some cases, MATLAB's own `libstdc++` library may be an old version, which leads an error while compiling the bindings, of the kind "version 'CXXABI_1.3.11' not found". In this case, one can set MATLAB to use another version of `libstdc++` with the `LD_PRELOAD` variable (see [here](https://alexxunxu.wordpress.com/2018/01/15/version-cxxabi_1-3-8-not-found/) for further reference). For example, for using the system's default `libstdc++`, one can open MATLAB with the following command:

```bash
LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6 matlab
```

The script uses `pkg-config` to determine the necessary flags. If `pkg-config` is unable to find the flags, the script will throw an error. Please refer to the [Linking to preCICE](https://precice.org/installation-linking.html) page in the preCICE wiki for details regarding `pkg-config`.

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

```bash
readBlockScalarData(int dataID, int size, const int *valueIndices, double *values)
```

is found in the MATLAB bindings as

```bash
values = readBlockScalarData(dataID, valueIndices)
```

## Out of process variant

The C++ MEX API supports [out of process execution](https://de.mathworks.com/help/matlab/matlab_external/out-of-process-execution-of-c-mex-functions.html) of MEX functions. This feature is implemented in the class `precice.SolverInterfaceOOP`. This class works exactly like `precice.SolverInterface`. Internally, however, the gateway function that calls the preCICE routines is run on a `mexHost` object.
This has the following advantages:

- Multiple instances of `SolverInterfaceOOP` can exist at the same time.
- If the gateway function crashes, then MATLAB will not crash. Only the mexHost object will crash.
However, using the OOP variant is **significantly** slower than the normal in process

## Troubleshooting

## `libprecice.so` cannot be found

```bash
Invalid MEX-file 'SOMEPATH/matlab-bindings/+precice/@SolverInterface/private/preciceGateway.mexa64':
libprecice.so.2: cannot open shared object file: No such file or directory.
```

Tells you that the MATLAB bindings cannot find the C++ library preCICE. Make sure that you [installed preCICE correctly](https://precice.org/installation-source-installation.html#testing-your-installation).

You can also run `pkg-config --cflags --libs libprecice` to see whether the paths provided by `pkg-config` point to the correct place. Example output, if everything is correct and you installed preCICE via `sudo make install`:

```bash
$ pkg-config --cflags --libs libprecice
-I/usr/local/include -L/usr/local/lib -lprecice
```

If everything until this point looks good and you are still facing problems and you installed preCICE to a custom location using `CMAKE_INSTALL_PREFIX`, MATLAB might not be able to find `libprecice.so`, since it is not discoverable. Please add the location of `libprecice.so` (see `pkg-config --libs-only-L libprecice`, without the `-L`) to your `LD_LIBRARY_PATH`. For further instructions refer to the [MATLAB documentation](https://de.mathworks.com/help/matlab/matlab_external/set-run-time-library-path-on-linux-systems.html).

## version \`GLIBCXX_3.4.26' not found

```bash
Invalid MEX-file 'SOMEPATH/matlab-bindings/+precice/@SolverInterface/private/preciceGateway.mexa64':
/usr/local/MATLAB/R2021a/bin/glnxa64/../../sys/os/glnxa64/libstdc++.so.6:
version `GLIBCXX_3.4.26' not found (required by /lib/x86_64-linux-gnu/libprecice.so.2)
```

Matlab ships with a version of `libstdc++.so.6` that may be too old. This version does not find the preCICE C++ library. By using the system-provided version of `libstdc++.so.6`, you can fix the error.

So far, this problem was encountered with Ubuntu Version `20.04.04 LTS`, GNU C++ `9.4.0`, on matlab versions `R2020b`, `R2021a`, `R2021b`.

To solve this error start matlab with the following command:

```shell
LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6 matlab
```

## Old versioning scheme

Bindings versions up to `v3.0.0.0` have four digits, where the first three digits are the supported preCICE version, and the fourth digit is the bindings version. Example: `v2.0.0.1` and `v2.0.0.2` of the bindings represent versions `1` and `2` of the bindings that are compatible with preCICE `v2.0.0`. We dropped the third digit of the preCICE version as bugfix releases are always compatible and do not impact the bindings. The new three digit format is now consistent with other preCICE bindings.

## Contributors

- [Dominik Volland](https://github.com/Dominanz) contributed first working prototype in [PR #494 on `precice/precice`](https://github.com/precice/precice/pull/494)
- [Gilberto Lem](https://github.com/gilbertolem) integrated bindings into existing infrastructure of preCICE in [PR #580 on `precice/precice`](https://github.com/precice/precice/pull/580)
- [Benjamin Rodenberg](https://github.com/BenjaminRodenberg)
- [Frédéric Simonis](https://github.com/fsimonis)
- [Erik Scheurer](https://github.com/erikscheurer) contributed automated CI tests.
