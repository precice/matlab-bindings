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
        writeDataName = 'dataOne';
        readDataName = 'dataTwo';
        meshName = 'MeshOne';
    end
    
    if (strcmp(participantName, 'SolverTwo'))
        readDataName = 'dataOne';
        writeDataName = 'dataTwo';
        meshName = 'MeshTwo';
    end
    
    numVertices = 3;
    
    solverProcessIndex = 0;
    solverProcessSize = 1;
    
    interface = precice.SolverInterface(participantName, configFileName, solverProcessIndex, solverProcessSize);
    
    meshID = interface.getMeshID(meshName);
    dims = interface.getDimensions();
    
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
    
    vertexIDs = interface.setMeshVertices(meshID, vertices);
    readDataID = interface.getDataID(readDataName, meshID);
    writeDataID = interface.getDataID(writeDataName, meshID);
    
    dt = interface.initialize();
    
    while(interface.isCouplingOngoing())
        if(interface.isActionRequired(precice.constants.actionWriteIterationCheckpoint()))
            disp('DUMMY: Writing iteration checkpoint.')
            interface.markActionFulfilled(precice.constants.actionWriteIterationCheckpoint());
        end
        
        if (interface.isReadDataAvailable())
            readData = interface.readBlockVectorData(readDataID, vertexIDs);
        end
        
        writeData = readData + 1;
        
        if (interface.isWriteDataRequired(dt))
            interface.writeBlockVectorData(writeDataID, vertexIDs, writeData);
        end
        
        dt = interface.advance(dt);
        
        if(interface.isActionRequired(precice.constants.actionReadIterationCheckpoint()))
            disp('DUMMY: Reading iteration checkpoint.')
            interface.markActionFulfilled(precice.constants.actionReadIterationCheckpoint());
        else
            disp('DUMMY: Advancing in time.')
        end
    end
    
    interface.finalize();
    disp('DUMMY: Closing MATLAB solverdummy.')
end
