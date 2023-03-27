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
        
        % initialize Data
        function initializeData(obj)
            feval(obj.oMexHost,"preciceGateway",uint8(11));
        end
        
        % advance
        function dt = advance(obj,dt)
            dt = feval(obj.oMexHost,"preciceGateway",uint8(12),dt);
        end
        
        % finalize
        function finalize(obj)
            feval(obj.oMexHost,"preciceGateway",uint8(13));
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
        function bool = isTimestepComplete(obj)
            bool = feval(obj.oMexHost,"preciceGateway",uint8(24));
        end
        
        % requiresInitialData
        function bool = requiresInitialData(obj)
            bool = feval(obj.oMexHost,"preciceGateway",uint8(25));
        end

        % requiresReadingCheckpoint
        function bool = requiresReadingCheckpoint(obj)
            bool = feval(obj.oMexHost,"preciceGateway",uint8(26));
        end

        % requiresWritingCheckpoint
        function bool = requiresWritingCheckpoint(obj)
            bool = feval(obj.oMexHost,"preciceGateway",uint8(27));
        end

        % getVersionInformation
        function s = getVersionInformation(obj)
            s = feval(obj.oMexHost,"preciceGateway",uint8(27));
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
        function bool = requiresMeshConnectivityFor(obj,meshName,dataName)
            if ischar(meshName)
                meshName = string(meshName);
            end
            if ischar(dataName)
                dataName = string(dataName);
            end
            bool = feval(obj.oMexHost,"preciceGateway",uint8(41),meshName,dataName);
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
        function vertexId = setMeshVertex(obj,meshID,position)
            vertexId = feval(obj.oMexHost,"preciceGateway",uint8(44),int32(meshID),position);
        end
        
        % getMeshVertexSize
        function vertexId = getMeshVertexSize(obj,meshID)
            vertexId = feval(obj.oMexHost,"preciceGateway",uint8(45),int32(meshID));
        end
        
        % setMeshVertices
        function vertexIds = setMeshVertices(obj,meshID,positions)
            obj.checkDimensions(size(positions, 1), obj.getDimensions())
            inSize = size(positions,2);
            vertexIds = feval(obj.oMexHost,"preciceGateway",uint8(46),int32(meshID),int32(inSize),positions);
        end
        
        % setMeshEdge
        function edgeID = setMeshEdge(obj, meshID, firstVertexID, secondVertexID)
            edgeID = feval(obj.oMexHost,"preciceGateway",uint8(49),int32(meshID),int32(firstVertexID),int32(secondVertexID));
        end

        % setMeshEdges
        function edgeIDs = setMeshEdges(obj, meshID, vertices)
            obj.checkDimensions(size(vertices,1), 2)
            inSize = size(vertices,2);
            edgeIDs = feval(obj.oMexHost,"preciceGateway",uint8(51),int32(meshID),int32(inSize),vertices);
        end
        
        % setMeshTriangle
        function setMeshTriangle(obj, meshID, firstEdgeID, secondEdgeID, thirdEdgeID)
            feval(obj.oMexHost,"preciceGateway",uint8(50),int32(meshID),int32(firstEdgeID),int32(secondEdgeID),int32(thirdEdgeID));
        end

        % setMeshTriangles
        function setMeshTriangles(obj, meshID, vertices)
            obj.checkDimensions(size(vertices,1), 3)
            inSize = size(vertices,2);
            feval(obj.oMexHost,"preciceGateway",uint8(53),int32(meshID),int32(inSize),vertices);
        end
        
        % setMeshQuad
        function setMeshQuad(obj, meshID, firstEdgeID, secondEdgeID, thirdEdgeID, fourthEdgeID)
            feval(obj.oMexHost,"preciceGateway",uint8(52),int32(meshID),int32(firstEdgeID),int32(secondEdgeID),int32(thirdEdgeID),int32(fourthEdgeID));
        end

        % setMeshQuads
        function setMeshQuads(obj, meshID, vertices)
            obj.checkDimensions(size(vertices,1), 4)
            inSize = size(vertices,2);
            feval(obj.oMexHost,"preciceGateway",uint8(54),int32(meshID),int32(inSize),edges);
        end

        % setMeshTetrahedron
        function setMeshTetrahedron(obj, meshID, firstVertexID, secondVertexID, thirdVertexID, fourthVertexID)
            feval(obj.oMexHost,"preciceGateway",uint8(55),int32(meshID),int32(firstVertexID),int32(secondVertexID),int32(thirdVertexID),int32(fourthVertexID));
        end

        % setMeshTetrahedra
        function setMeshTetrahedra(obj, meshID, vertices)
            obj.checkDimensions(size(vertices,1), 4)
            inSize = size(vertices,2);
            feval(obj.oMexHost,"preciceGateway",uint8(56),int32(meshID),int32(inSize),vertices);
        end
        
        % setMeshAccessRegion - EXPERIMENTAL
        function setMeshAccessRegion(meshID, boundingBox)
            preciceGateway(uint8(55),int32(meshID),boundingBox)
        end

        % getMeshVerticesAndIDs - EXPERIMENTAL
        function [vertices, outIDs] = getMeshVerticesAndIDs(meshID)
            inSize = getMeshVertexSize(meshID);
            [vertices,outIDs] = preciceGateway(uint8(56),int32(meshID),int32(inSize));
        end
        
        %% Data Access
        % hasData
        function bool = hasData(obj,dataName,meshID)
            if ischar(dataName)
                dataName = string(dataName);
            end
            bool = feval(obj.oMexHost,"preciceGateway",uint8(60),dataName,int32(meshID));
        end
        
        % mapReadDataTo
        function mapReadDataTo(obj,meshID)
            feval(obj.oMexHost,"preciceGateway",uint8(62),int32(meshID));
        end
        
        % mapWriteDataFrom
        function mapWriteDataFrom(obj,meshID)
            feval(obj.oMexHost,"preciceGateway",uint8(63),int32(meshID));
        end
        
        % writeBlockVectorData
        function writeBlockVectorData(obj,dataID,valueIndices,values)
            if ~isa(valueIndices,'int32')
                warning('valueIndices should be allocated as int32 to prevent copying.');
                valueIndices = int32(valueIndices);
            end
            inSize = length(valueIndices);
            obj.checkDimensions(size(values, 2), inSize)
            obj.checkDimensions(size(values, 1), obj.getDimensions())
            feval(obj.oMexHost,"preciceGateway",uint8(64),int32(dataID),int32(inSize),valueIndices,values);
        end
        
        % writeVectorData
        function writeVectorData(obj,dataID,valueIndex,value)
            feval(obj.oMexHost,"preciceGateway",uint8(65),int32(dataID),int32(valueIndex),value);
        end
        
        % writeBlockScalarData
        function writeBlockScalarData(obj,dataID,valueIndices,values)
            if ~isa(valueIndices,'int32')
                warning('valueIndices should be allocated as int32 to prevent copying.');
                valueIndices = int32(valueIndices);
            end
            inSize = length(valueIndices);
            assert(inSize == length(values), 'valueIndices and values should must have the same length');
            feval(obj.oMexHost,"preciceGateway",uint8(66),int32(dataID),int32(inSize),valueIndices,values);
        end
        
        % writeScalarData
        function writeScalarData(obj,dataID,valueIndex,value)
            feval(obj.oMexHost,"preciceGateway",uint8(67),int32(dataID),int32(valueIndex),value);
        end
        
        % readBlockVectorData
        function values = readBlockVectorData(obj,dataID,valueIndices)
            if ~isa(valueIndices,'int32')
                warning('valueIndices should be allocated as int32 to prevent copying.');
                valueIndices = int32(valueIndices);
            end
            inSize = length(valueIndices);
            values = feval(obj.oMexHost,"preciceGateway",uint8(68),int32(dataID),int32(inSize),valueIndices);
        end
        
        % readVectorData
        function value = readVectorData(obj,dataID,valueIndex)
            value = feval(obj.oMexHost,"preciceGateway",uint8(69),int32(dataID),int32(valueIndex));
        end
        
        % readBlockScalarData
        function values = readBlockScalarData(obj,dataID,valueIndices,transpose)
            if nargin<4
                transpose=false;
            end
            if ~isa(valueIndices,'int32')
                warning('valueIndices should be allocated as int32 to prevent copying.');
                valueIndices = int32(valueIndices);
            end
            inSize = length(valueIndices);
            values = feval(obj.oMexHost,"preciceGateway",uint8(70),int32(dataID),int32(inSize),valueIndices,transpose);
        end
        
        % readScalarData
        function value = readScalarData(obj,dataID,valueIndex)
            value = feval(obj.oMexHost,"preciceGateway",uint8(71),int32(dataID),int32(valueIndex));
        end

        %% Data Access
        % writeBlockVectorGradientData
        function writeBlockVectorGradientData(obj, dataID, valueIndices, gradientValues)
            if ~isa(valueIndices, 'int32')
                warning('valueIndices should be allocated as int32 to prevent copying.');
                valueIndices = int32(valueIndices);
            end

            inSize = length(valueIndices);
            obj.checkDimensions(size(gradientValues, 2), inSize)
            obj.checkDimensions(size(gradientValues, 1), obj.getDimensions() * obj.getDimensions())
            feval(obj.oMexHost, "preciceGateway", uint8(73), int32(dataID), int32(inSize), valueIndices, gradientValues);
        end

        % writeVectorGradientData
        function writeVectorGradientData(obj, dataID, valueIndex, gradientValues)
            obj.checkDimensions(size(gradientValues, 1), obj.getDimensions() * obj.getDimensions())
            feval(obj.oMexHost, "preciceGateway", uint8(74), int32(dataID), int32(valueIndex), gradientValues);
        end

        % writeBlockScalarGradientData
        function writeBlockScalarGradientData(obj, dataID, valueIndices, gradientValues)

            if ~isa(valueIndices, 'int32')
                warning('valueIndices should be allocated as int32 to prevent copying.');
                valueIndices = int32(valueIndices);
            end

            inSize = length(valueIndices);
            obj.checkDimensions(size(gradientValues, 2), inSize)
            obj.checkDimensions(size(gradientValues, 1), obj.getDimensions())
            feval(obj.oMexHost, "preciceGateway", uint8(75), int32(dataID), int32(inSize), valueIndices, gradientValues);
        end

        % writeScalarGradientData
        function writeScalarGradientData(obj, dataID, valueIndex, gradientValues)
            obj.checkDimensions(size(gradientValues, 1), obj.getDimensions())
            feval(obj.oMexHost, "preciceGateway", uint8(76), int32(dataID), int32(valueIndex), gradientValues);
        end

        %% Helper functions
        % Check for dxn convention
        function checkDimensions(obj, a, b)
            assert(a ==  b, 'The shape of the matrices must be [dim numVertices], where dim is the problem dimension');
        end
    end
end
