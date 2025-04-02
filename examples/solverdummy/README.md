# MATLAB solverdummy

This dummy illustrates the use of preCICE with MATLAB using the MATLAB bindings based on the C data API.

## Compilation

No compiling is necessary. You only have to compile the MATLAB bindings.

## Run

To run the dummy, open two MATLAB instances and call

* `solverdummy precice-config.xml SolverOne`
* `solverdummy precice-config.xml SolverTwo`

Since `solverdummy` is a MATLAB function and MATLAB treats blank space separated arguments as char arrays, you can equivalently call

`solverdummy('precice-config.xml','SolverOne')`

and analogously for the second call.
Naturally, you may also couple the MATLAB dummy with another dummy instead.
