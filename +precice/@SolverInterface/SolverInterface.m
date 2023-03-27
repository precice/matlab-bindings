classdef SolverInterface < handle
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
    end
    
    methods
        %% Construction
        % Constructor
        function obj = SolverInterface(SolverName,configFileName,solverProcessIndex,solverProcessSize)
            %SOLVERINTERFACE Construct an instance of this class
            if (solverProcessIndex > 0 || solverProcessSize > 1)
                error('Parallel runs are currently not supported with the MATLAB bindings.')    
            end
            if ischar(SolverName)
                SolverName = string(SolverName);
            end
            if ischar(configFileName)
                configFileName = string(configFileName);
            end
            preciceGateway(uint8(0),SolverName,configFileName,int32(solverProcessIndex),int32(solverProcessSize));
        end
        
        % Destructor
        function delete(obj)
            % Delete the mex host
            preciceGateway(uint8(1));
        end
        
        %% Steering methods
        % initialize
        function dt = initialize(obj)
            dt = preciceGateway(uint8(10));
        end
        
        % initialize Data
        function initializeData(obj)
            preciceGateway(uint8(11));
        end
        
        % advance
        function dt = advance(obj,dt)
            dt = preciceGateway(uint8(12),dt);
        end
        
        % finalize
        function finalize(obj)
            preciceGateway(uint8(13));
        end
        
        %% Status queries
        % getDimensions
        function dims = getDimensions(obj)
            dims = preciceGateway(uint8(20));
        end
        
        % isCouplingOngoing
        function bool = isCouplingOngoing(obj)
            bool = preciceGateway(uint8(21));
        end
        
        % isTimeWindowComplete
        function bool = isTimeWindowComplete(obj)
            bool = preciceGateway(uint8(24));
        end
        
        % isReadDataAvailable
        function bool = requiresReadingCheckpoint(obj)
            bool = preciceGateway(uint8(22));
        end
        
        % isWriteDataRequired
        function bool = requiresWritingCheckpoint(obj)
            bool = preciceGateway(uint8(23));
        end

        %% Mesh Access
        % hasMesh
        function bool = hasMesh(obj,meshName)
            if ischar(meshName)
                meshName = string(meshName);
            end
            bool = preciceGateway(uint8(40),meshName);
        end
        % setMeshVertex
        function vertexId = setMeshVertex(obj,meshID,position)
            vertexId = preciceGateway(uint8(44),int32(meshID),position);
        end

        % requiresGradientDataFor
        function bool = requiresGradientDataFor(obj,meshName,dataName)
            if ischar(meshName)
                meshName = string(meshName);
            end
            if ischar(dataName)
                dataName = string(dataName);
            end
            bool = preciceGateway(uint8(25),meshName,dataName);
        end
        
        % getMeshVertexSize
        function vertexId = getMeshVertexSize(obj,meshID)
            vertexId = preciceGateway(uint8(45),int32(meshID));
        end
        
        % setMeshVertices
        function vertexIds = setMeshVertices(obj,meshID,positions)
            obj.checkDimensions(size(positions, 1), obj.getDimensions())
            inSize = size(positions, 2);
            vertexIds = preciceGateway(uint8(46),int32(meshID),int32(inSize),positions);
        end
        
        % setMeshEdge
        function edgeID = setMeshEdge(obj, meshID, firstVertexID, secondVertexID)
            edgeID = preciceGateway(uint8(49),int32(meshID),int32(firstVertexID),int32(secondVertexID));
        end

        % setMeshEdges
        function edgeIDs = setMeshEdges(obj, meshID, vertices)
            edgeIDs = preciceGateway(uint8(51),int32(meshID),vetices)
        end

        % setMeshTriangle
        function setMeshTriangle(obj, meshID, firstVertexId, secondVertexId, thirdVertexId)
            preciceGateway(uint8(50),int32(meshID),int32(firstVertexId),int32(secondVertexId),int32(thirdVertexId));
        end
        
        % setMeshTriangles
        function setMeshTriangles(obj, meshID, vertices)
            preciceGateway(uint8(54),int32(meshID),vertices)
        end
        
        % setMeshQuad
        function setMeshQuad(obj, meshID, firstVertexId, secondVertexId, thirdVertexId, fourthVertexId)
            preciceGateway(uint8(52),int32(meshID),int32(firstVertexId),int32(secondVertexId),int32(thirdVertexId),int32(fourthVertexId));
        end

        % setMeshQuads
        function setMeshQuads(obj, meshID, vertices)
            preciceGateway(uint8(57),int32(meshID),vertices)
        end

        % setMeshTetrahedron
        function setMeshTetrahedron(obj, meshID, firstVertexId, secondVertexId, thirdVertexId, fourthVertexId)
            preciceGateway(uint8(53),int32(meshID),int32(firstVertexId),int32(secondVertexId),int32(thirdVertexId),int32(fourthVertexId));
        end
        
        % setMeshTetrahedra
        function setMeshTetrahedra(obj, meshID, vertices)
            preciceGateway(uint8(58),int32(meshID),vertices)
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
        % hasDataID
        function bool = hasData(obj,dataName,meshID)
            if ischar(dataName)
                dataName = string(dataName);
            end
            bool = preciceGateway(uint8(60),dataName,int32(meshID));
        end
        
        % mapReadDataTo
        function mapReadDataTo(obj,meshID)
            preciceGateway(uint8(62),int32(meshID));
        end
        
        % mapWriteDataFrom
        function mapWriteDataFrom(obj,meshID)
            preciceGateway(uint8(63),int32(meshID));
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
            preciceGateway(uint8(64),int32(dataID),int32(inSize),valueIndices,values);
        end
        
        % writeVectorData
        function writeVectorData(obj,dataID,valueIndex,value)
            preciceGateway(uint8(65),int32(dataID),int32(valueIndex),value);
        end
        
        % writeBlockScalarData
        function writeBlockScalarData(obj,dataID,valueIndices,values)
            if ~isa(valueIndices,'int32')
                warning('valueIndices should be allocated as int32 to prevent copying.');
                valueIndices = int32(valueIndices);
            end
            inSize = length(valueIndices);
            assert(inSize == length(values), 'valueIndices and values should must have the same length');
            preciceGateway(uint8(66),int32(dataID),int32(inSize),valueIndices,values);
        end
        
        % writeScalarData
        function writeScalarData(obj,dataID,valueIndex,value)
            preciceGateway(uint8(67),int32(dataID),int32(valueIndex),value);
        end
        
        % readBlockVectorData
        function values = readBlockVectorData(obj,dataID,valueIndices)
            if ~isa(valueIndices,'int32')
                warning('valueIndices should be allocated as int32 to prevent copying.');
                valueIndices = int32(valueIndices);
            end
            inSize = length(valueIndices);
            values = preciceGateway(uint8(68),int32(dataID),int32(inSize),valueIndices);
        end
        
        % readVectorData
        function value = readVectorData(obj,dataID,valueIndex)
            value = preciceGateway(uint8(69),int32(dataID),int32(valueIndex));
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
            values = preciceGateway(uint8(70),int32(dataID),int32(inSize),valueIndices,transpose);
        end
        
        % readScalarData
        function value = readScalarData(obj,dataID,valueIndex)
            value = preciceGateway(uint8(71),int32(dataID),int32(valueIndex));
        end

        % writeBlockVectorGradientData
        function writeBlockVectorGradientData(obj, dataID, valueIndices, gradientValues)
            if ~isa(valueIndices, 'int32')
                warning('valueIndices should be allocated as int32 to prevent copying.');
                valueIndices = int32(valueIndices);
            end

            inSize = length(valueIndices);
            obj.checkDimensions(size(gradientValues, 2), inSize)
            obj.checkDimensions(size(gradientValues, 1), obj.getDimensions() * obj.getDimensions())
            preciceGateway(uint8(73), int32(dataID), int32(inSize), valueIndices, gradientValues);
        end

        % writeVectorGradientData
        function writeVectorGradientData(obj, dataID, valueIndex, gradientValues)
            preciceGateway(uint8(74), int32(dataID), int32(valueIndex), gradientValues);
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
            preciceGateway(uint8(75), int32(dataID), int32(inSize), valueIndices, gradientValues);
        end

        % writeScalarGradientData
        function writeScalarGradientData(obj, dataID, valueIndex, gradientValues)
            preciceGateway(uint8(76), int32(dataID), int32(valueIndex), gradientValues);
        end

        %% Helper functions
        % Check for dxn convention
        function checkDimensions(obj, a, b)
            assert(a ==  b, 'The shape of the matrices must be [dim numVertices], where dim is the problem dimension');
        end
    end
end
