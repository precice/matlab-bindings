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
    
    while(interface.isCouplingOngoing())
        if interface.requiresWritingCheckpoint()
            disp('DUMMY: Writing iteration checkpoint.')
        end
        
        dt = interface.getMaxTimeStepSize();

        readData = interface.readData(meshName, readDataName, vertexIDs, dt);

        writeData = readData + 1;
        disp(writeData)
        interface.writeData(meshName, writeDataName, vertexIDs, writeData);

        interface.advance(dt);

        if interface.requiresReadingCheckpoint()
            disp('DUMMY: Reading iteration checkpoint.')
        else
            disp('DUMMY: Advancing in time.')
        end
    end
    
    interface.finalize();
end
