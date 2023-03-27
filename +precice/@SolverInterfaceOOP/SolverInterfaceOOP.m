classdef SolverInterfaceOOP < precice.SolverInterface
    %SOLVERINTERFACE Matlab wrapper for the C++ SolverInterface
    %   This class will serve as a gateway for the precice Solver Interface
    %   in C++. It has access to a private mex Function written in the new
    %   MATLAB C++ API. Such a function is actually an instance of a C++ 
    %   class that is stored internally by MATLAB. Whenever they are 
    %   "called", a subroutine of the object (operator ()) is invoked which
    %   then has access to the members of the class.
    %   Hence, we can store the actual solver interface in this class and
    %   access it by invoking the mex function.
    
    properties(Access=private)
        % Possible changes:
        % - Allow the creation of multiple SolverInterfaces. For this, we
        % should replace the interface pointer in the Gateway by a list of 
        % interface pointers and add an InterfaceID as property of this
        % class.
        
        % mex host managing the out of process execution
        oMexHost;
        
        % bool set to true after oMexHost started running
        bMexHostRunning = 0;
    end
    
    methods
        %% Construction
        % Constructor
        function obj = SolverInterface(SolverName,configFileName,solverProcessIndex,solverProcessSize)
            %SOLVERINTERFACE Construct an instance of this class
            % Initialize the mex host
            obj.oMexHost = mexhost;
            obj.bMexHostRunning = true;
            
            if (solverProcessIndex > 0 || solverProcessSize > 1)
                error('Parallel runs are currently not supported with the MATLAB bindings.')    
            end
            if ischar(SolverName)
                SolverName = string(SolverName);
            end
            if ischar(configFileName)
                configFileName = string(configFileName);
            end
            feval(obj.oMexHost,"preciceGateway",uint8(0),SolverName,configFileName,int32(solverProcessIndex),int32(solverProcessSize));
        end
        
        % Destructor
        function delete(obj)
            % Delete the mex host
            feval(obj.oMexHost,"preciceGateway",uint8(1));
            delete(obj.oMexHost);
        end
        
        %% Steering methods
        % initialize
        function dt = initialize(obj)
            dt = feval(obj.oMexHost,"preciceGateway",uint8(10));
        end
        
        % advance
        function dt = advance(obj,dt)
            dt = feval(obj.oMexHost,"preciceGateway",uint8(11),dt);
        end
        
        % finalize
        function finalize(obj)
            feval(obj.oMexHost,"preciceGateway",uint8(12));
        end
        
        %% Status queries
        % getDimensions
        function dims = getDimensions(obj)
            dims = feval(obj.oMexHost,"preciceGateway",uint8(20));
        end
        
        % isCouplingOngoing
        function bool = isCouplingOngoing(obj)
            bool = feval(obj.oMexHost,"preciceGateway",uint8(21));
        end
        
        % isTimestepComplete
        function bool = isTimeWindowComplete(obj)
            bool = feval(obj.oMexHost,"preciceGateway",uint8(22));
        end

        % requiresInitialData
        function bool = requiresInitialData(obj)
            bool = feval(obj.oMexHost,"preciceGateway",uint8(23));
        end

        % requiresReadingCheckpoint
        function bool = requiresReadingCheckpoint(obj)
            bool = feval(obj.oMexHost,"preciceGateway",uint8(24));
        end

        % requiresWritingCheckpoint
        function bool = requiresWritingCheckpoint(obj)
            bool = feval(obj.oMexHost,"preciceGateway",uint8(25));
        end

        % getVersionInformation
        function s = getVersionInformation(obj)
            s = feval(obj.oMexHost,"preciceGateway",uint8(26));
        end

        %% Mesh Access
        % hasMesh
        function bool = hasMesh(obj,meshName)
            if ischar(meshName)
                meshName = string(meshName);
            end
            bool = feval(obj.oMexHost,"preciceGateway",uint8(40),meshName);
        end

        % requiresMeshConnectivityFor
        function bool = requiresMeshConnectivityFor(obj,meshName)
            if ischar(meshName)
                meshName = string(meshName);
            end
            bool = feval(obj.oMexHost,"preciceGateway",uint8(41),meshName);
        end

        % requiresGradientDataFor
        function bool = requiresGradientDataFor(obj,meshName,dataName)
            if ischar(meshName)
                meshName = string(meshName);
            end
            if ischar(dataName)
                dataName = string(dataName);
            end
            bool = feval(obj.oMexHost,"preciceGateway",uint8(42),meshName,dataName);
        end
        
        % setMeshVertex
        function vertexId = setMeshVertex(obj,meshName,position)
            if ischar(meshName)
                meshName = string(meshName)
            end
            vertexId = feval(obj.oMexHost,"preciceGateway",uint8(43),meshName,position);
        end

        % getMeshVertexSize
        function vertexId = getMeshVertexSize(obj,meshName)
            if ischar(meshName)
                meshName = string(meshName)
            end
            vertexId = feval(obj.oMexHost,"preciceGateway",uint8(44),meshName);
        end
        
        % setMeshVertices
        function vertexIds = setMeshVertices(obj,meshName,positions)
            if ischar(meshName)
                meshName = string(meshName)
            end
            obj.checkDimensions(size(positions, 1), obj.getDimensions())
            inSize = size(positions,2);
            vertexIds = feval(obj.oMexHost,"preciceGateway",uint8(45),meshName,int32(inSize),positions);
        end
        
        % setMeshEdge
        function edgeID = setMeshEdge(obj, meshName, firstVertexID, secondVertexID)
            if ischar(meshName)
                meshName = string(meshName)
            end
            edgeID = feval(obj.oMexHost,"preciceGateway",uint8(46),meshName,int32(firstVertexID),int32(secondVertexID));
        end

        % setMeshEdges
        function edgeIDs = setMeshEdges(obj, meshName, vertices)
            if ischar(meshName)
                meshName = string(meshName)
            end
            obj.checkDimensions(size(vertices,1), 2)
            inSize = size(vertices,2);
            edgeIDs = feval(obj.oMexHost,"preciceGateway",uint8(47),meshName,int32(inSize),vertices);
        end

        % setMeshTriangle
        function setMeshTriangle(obj, meshName, firstVertexID, secondVertexID, thirdVertexID)
            if ischar(meshName)
                meshName = string(meshName)
            end
            feval(obj.oMexHost,"preciceGateway",uint8(48),meshName,int32(firstVertexID),int32(secondVertexID),int32(thirdVertexID));
        end

        % setMeshTriangles
        function setMeshTriangles(obj, meshName, vertices)
            obj.checkDimensions(size(vertices,1), 3)
            inSize = size(vertices,2);
            if ischar(meshName)
                meshName = string(meshName)
            end
            feval(obj.oMexHost,"preciceGateway",uint8(49),meshName,int32(inSize),vertices);
        end
        
        % setMeshQuad
        function setMeshQuad(obj, meshName, firstVertexID, secondVertexID, thirdVertexID, fourthVertexID)
            if ischar(meshName)
                meshName = string(meshName)
            end
            feval(obj.oMexHost,"preciceGateway",uint8(50),meshName,int32(firstVertexID),int32(secondVertexID),int32(thirdVertexID),int32(fourthVertexID));
        end

        % setMeshQuads
        function setMeshQuads(obj, meshName, vertices)
            if ischar(meshName)
                meshName = string(meshName)
            end
            obj.checkDimensions(size(vertices,1), 4)
            inSize = size(vertices,2);
            feval(obj.oMexHost,"preciceGateway",uint8(51),meshName,int32(inSize),edges);
        end

        % setMeshTetrahedron
        function setMeshTetrahedron(obj, meshName, firstVertexID, secondVertexID, thirdVertexID, fourthVertexID)
            if ischar(meshName)
                meshName = string(meshName)
            end
            feval(obj.oMexHost,"preciceGateway",uint8(52),meshName,int32(firstVertexID),int32(secondVertexID),int32(thirdVertexID),int32(fourthVertexID));
        end

        % setMeshTetrahedra
        function setMeshTetrahedra(obj, meshName, vertices)
            obj.checkDimensions(size(vertices,1), 4)
            inSize = size(vertices,2);
            if ischar(meshName)
                meshName = string(meshName)
            end
            feval(obj.oMexHost,"preciceGateway",uint8(53),meshName,int32(inSize),vertices);
        end
        
        % setMeshAccessRegion
        function setMeshAccessRegion(meshName, boundingBox)
            if ischar(meshName)
                meshName = string(meshName)
            end
            feval(obj.oMexHost,"preciceGateway",uint8(54),meshName,boundingBox);
        end

        % getMeshVerticesAndIDs
        function [vertices, outIDs] = getMeshVerticesAndIDs(meshName)
            if ischar(meshName)
                meshName = string(meshName)
            end
            inSize = getMeshVertexSize(meshName);
            [vertices,outIDs] = feval(obj.oMexHost,"preciceGateway",uint8(55),meshName,int32(inSize));
        end

        %% Data Access
        % hasData
        function bool = hasData(obj,meshName,dataName)
            if ischar(meshName)
                meshName = string(meshName)
            end
            if ischar(dataName)
                dataName = string(dataName);
            end
            bool = feval(obj.oMexHost,"preciceGateway",uint8(60),dataName,meshName);
        end
        
        % writeBlockVectorData
        function writeBlockVectorData(obj,meshName,dataName,valueIndices,values)
            if ~isa(valueIndices,'int32')
                warning('valueIndices should be allocated as int32 to prevent copying.');
                valueIndices = int32(valueIndices);
            end
            if ischar(meshName)
                meshName = string(meshName)
            end
            if ischar(dataName)
                dataName = string(dataName)
            end

            inSize = length(valueIndices);
            obj.checkDimensions(size(values, 2), inSize)
            obj.checkDimensions(size(values, 1), obj.getDimensions())
            feval(obj.oMexHost,"preciceGateway",uint8(61),meshName,dataName,int32(inSize),valueIndices,values);
        end
        
        % writeVectorData
        function writeVectorData(obj,meshName,dataName,valueIndex,value)
            if ischar(meshName)
                meshName = string(meshName)
            end
            if ischar(dataName)
                dataName = string(dataName)
            end
            feval(obj.oMexHost,"preciceGateway",uint8(62),meshName,dataName,int32(valueIndex),value);
        end
        
        % writeBlockScalarData
        function writeBlockScalarData(obj,meshName,dataName,valueIndices,values)
            if ~isa(valueIndices,'int32')
                warning('valueIndices should be allocated as int32 to prevent copying.');
                valueIndices = int32(valueIndices);
            end
            if ischar(meshName)
                meshName = string(meshName)
            end
            if ischar(dataName)
                dataName = string(dataName)
            end
            inSize = length(valueIndices);
            assert(inSize == length(values), 'valueIndices and values should must have the same length');
            feval(obj.oMexHost,"preciceGateway",uint8(63),meshName,dataName,int32(inSize),valueIndices,values);
        end
        
        % writeScalarData
        function writeScalarData(obj,meshName,dataName,valueIndex,value)
            if ischar(meshName)
                meshName = string(meshName)
            end
            if ischar(dataName)
                dataName = string(dataName)
            end
            feval(obj.oMexHost,"preciceGateway",uint8(64),meshName,dataName,int32(valueIndex),value);
        end
        
        % readBlockVectorData
        function values = readBlockVectorData(obj,meshName,dataName,valueIndices)
            if ~isa(valueIndices,'int32')
                warning('valueIndices should be allocated as int32 to prevent copying.');
                valueIndices = int32(valueIndices);
            end
            if ischar(meshName)
                meshName = string(meshName)
            end
            if ischar(dataName)
                dataName = string(dataName)
            end
            inSize = length(valueIndices);
            values = feval(obj.oMexHost,"preciceGateway",uint8(65),meshName,dataName,int32(inSize),valueIndices);
        end
        
        % readVectorData
        function value = readVectorData(obj,meshName,dataName,valueIndex)
            if ischar(meshName)
                meshName = string(meshName)
            end
            if ischar(dataName)
                dataName = string(dataName)
            end
            value = feval(obj.oMexHost,"preciceGateway",uint8(66),meshName,dataName,int32(valueIndex));
        end
        
        % readBlockScalarData
        function values = readBlockScalarData(obj,meshName,dataName,valueIndices,transpose)
            if nargin<4
                transpose=false;
            end
            if ~isa(valueIndices,'int32')
                warning('valueIndices should be allocated as int32 to prevent copying.');
                valueIndices = int32(valueIndices);
            end
            if ischar(meshName)
                meshName = string(meshName)
            end
            if ischar(dataName)
                dataName = string(dataName)
            end
            inSize = length(valueIndices);
            values = feval(obj.oMexHost,"preciceGateway",uint8(67),meshName,dataName,int32(inSize),valueIndices,transpose);
        end
        
        % readScalarData
        function value = readScalarData(obj,meshName,dataName,valueIndex)
            if ischar(meshName)
                meshName = string(meshName)
            end
            if ischar(dataName)
                dataName = string(dataName)
            end
            value = feval(obj.oMexHost,"preciceGateway",uint8(68),meshName,dataName,int32(valueIndex));
        end

        %% Data Access
        % writeBlockVectorGradientData
        function writeBlockVectorGradientData(obj, meshName, dataName, valueIndices, gradientValues)
            if ~isa(valueIndices, 'int32')
                warning('valueIndices should be allocated as int32 to prevent copying.');
                valueIndices = int32(valueIndices);
            end
            if ischar(meshName)
                meshName = string(meshName)
            end
            if ischar(dataName)
                dataName = string(dataName)
            end
            inSize = length(valueIndices);
            obj.checkDimensions(size(gradientValues, 2), inSize)
            obj.checkDimensions(size(gradientValues, 1), obj.getDimensions() * obj.getDimensions())
            feval(obj.oMexHost, "preciceGateway", uint8(69), meshName,dataName, int32(inSize), valueIndices, gradientValues);
        end

        % writeVectorGradientData
        function writeVectorGradientData(obj, meshName, dataName, valueIndex, gradientValues)
            obj.checkDimensions(size(gradientValues, 1), obj.getDimensions() * obj.getDimensions())
            if ischar(meshName)
                meshName = string(meshName)
            end
            if ischar(dataName)
                dataName = string(dataName)
            end
            feval(obj.oMexHost, "preciceGateway", uint8(70), meshName,dataName, int32(valueIndex), gradientValues);
        end

        % writeBlockScalarGradientData
        function writeBlockScalarGradientData(obj, meshName, dataName, valueIndices, gradientValues)

            if ~isa(valueIndices, 'int32')
                warning('valueIndices should be allocated as int32 to prevent copying.');
                valueIndices = int32(valueIndices);
            end
            if ischar(meshName)
                meshName = string(meshName)
            end
            if ischar(dataName)
                dataName = string(dataName)
            end

            inSize = length(valueIndices);
            obj.checkDimensions(size(gradientValues, 2), inSize)
            obj.checkDimensions(size(gradientValues, 1), obj.getDimensions())
            feval(obj.oMexHost, "preciceGateway", uint8(71), meshName,dataName, int32(inSize), valueIndices, gradientValues);
        end

        % writeScalarGradientData
        function writeScalarGradientData(obj, meshName, dataName, valueIndex, gradientValues)
            obj.checkDimensions(size(gradientValues, 1), obj.getDimensions())
            if ischar(meshName)
                meshName = string(meshName)
            end
            if ischar(dataName)
                dataName = string(dataName)
            end
            feval(obj.oMexHost, "preciceGateway", uint8(72), meshName,dataName, int32(valueIndex), gradientValues);
        end

        %% Helper functions
        % Check for dxn convention
        function checkDimensions(obj, a, b)
            assert(a ==  b, 'The shape of the matrices must be [dim numVertices], where dim is the problem dimension');
        end
    end
end
