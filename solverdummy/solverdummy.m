% MATLAB solverdummy.
% To use it, don't forget to install the matlab bindings and add them to
% the path
function solverdummy(configFileName,participantName)
    if nargin~=2
        disp('Usage: solverdummy configFile solverName');
        disp('');
        disp('Parameter description');
        disp('  configurationFile: Path and filename of preCICE configuration');
        disp('  participantName:        SolverDummy participant name in preCICE configuration');
        return;
    end
    
    if (strcmp(participantName, 'SolverOne'))
        writeDataName = 'Data-One';
        readDataName = 'Data-Two';
        meshName = 'SolverOne-Mesh';
    end
    
    if (strcmp(participantName, 'SolverTwo'))
        readDataName = 'Data-One';
        writeDataName = 'Data-Two';
        meshName = 'SolverTwo-Mesh';
    end
    
    numVertices = 3;

    disp('DUMMY: Starting MATLAB solverdummy with the following parameters:')
    disp(['DUMMY:   configFileName: ', configFileName])
    disp(['DUMMY:   participantName: ', participantName])
    
    ProcessIndex = 0;
    ProcessSize = 1;
    
    interface = precice.Participant(participantName, configFileName, ProcessIndex, ProcessSize);
    
    dims = interface.getMeshDimensions(meshName);
    
    vertices(dims, numVertices) = 0;
    readData(dims, numVertices) = 0;
    writeData(dims, numVertices) = 0;
    
    for x = 1 : numVertices
        for y = 1 : dims
            vertices(y, x) = x;
            readData(y, x) = x;
            writeData(y, x) = x;
        end
    end
    
    vertexIDs = interface.setMeshVertices(meshName, vertices);

    if interface.requiresInitialData()
        disp("DUMMY: Writing initial data.")
    end
    
    interface.initialize();
    disp('DUMMY: Initialized MATLAB solverdummy.')
    
    while(interface.isCouplingOngoing())
        disp('DUMMY: Starting a new coupling iteration.')
        if interface.requiresWritingCheckpoint()
            disp('DUMMY: Writing iteration checkpoint.')
        end
        
        dt = interface.getMaxTimeStepSize();
        disp(['DUMMY:   dt: ', num2str(dt)])
        readData = interface.readData(meshName, readDataName, vertexIDs, dt);
        disp(['DUMMY:   readData: ', num2str(readData)])
        writeData = readData + 1;
        disp(['DUMMY:   writeData: ', num2str(writeData)])
        interface.writeData(meshName, writeDataName, vertexIDs, writeData);
        disp('DUMMY:   wrote data.')
        interface.advance(dt);
        disp('DUMMY:   advanced.')
        if interface.requiresReadingCheckpoint()
            disp('DUMMY: Reading iteration checkpoint.')
        else
            disp('DUMMY: Advancing in time.')
        end
        disp('DUMMY: Finished coupling iteration.')
    end
    
    interface.finalize();
    disp('DUMMY: Closing MATLAB solverdummy.')
end
