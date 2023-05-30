% Script for compiling the MATLAB bindings for preCICE

% Get the path to the binding files. Use mfilename to get the full path of
% the current file. Thus, the script will work even if the user calls it
% from a different folder
path = string(fileparts(mfilename('fullpath')));
path_Interface = strjoin([path,"+precice","@Participant","private","preciceGateway"],filesep);
path_namespace_precice = strjoin([path, "+precice", "private", "preciceGateway"],filesep);

% Get the flags for linking to preCICE
[status,flags] = system('pkg-config --cflags --libs libprecice');
if status==1
    error("pkg-config was unable to determine the compiler flags for preCICE.")
end
flags = strsplit(flags);

% Run mex commands to compile
mex(strcat(path_Interface,".cpp"),'CXXFLAGS="-std=c++17 -fPIC"',"-output",path_Interface,flags{:});
mex(strcat(path_namespace_precice,".cpp"),'CXXFLAGS="-std=c++17 -fPIC"',"-output",path_namespace_precice,flags{:});
