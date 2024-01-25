classdef ParticipantOOP < precice.Participant
    %PARTICIPANT Matlab wrapper for the C++ Participant
    %   This class will serve as a gateway for the precice Participant
    %   in C++. It has access to a private mex Function written in the new
    %   MATLAB C++ API. Such a function is actually an instance of a C++
    %   class that is stored internally by MATLAB. Whenever they are
    %   "called", a subroutine of the object (operator ()) is invoked which
    %   then has access to the members of the class.
    %   Hence, we can store the actual participant in this class and
    %   access it by invoking the mex function.
    
    properties(Access=private)
        % Possible changes:
        % - Allow the creation of multiple Participants. For this, we
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
        function obj = Participant(ParticipantName,configFileName,ProcessIndex,ProcessSize)
            %PARTICIPANT Construct an instance of this class
            % Initialize the mex host
            obj.oMexHost = mexhost;
            obj.bMexHostRunning = true;
            
            if (ProcessIndex > 0 || ProcessSize > 1)
                error('Parallel runs are currently not supported with the MATLAB bindings.')
            end
            if ischar(ParticipantName)
                ParticipantName = string(ParticipantName);
            end
            if ischar(configFileName)
                configFileName = string(configFileName);
            end
            feval(obj.oMexHost,"preciceGateway",uint8(0),ParticipantName,configFileName,int32(ProcessIndex),int32(ProcessSize));
        end
        
        % Destructor
        function delete(obj)
            % Delete the mex host
            feval(obj.oMexHost,"preciceGateway",uint8(1));
            delete(obj.oMexHost);
        end
        
        %% Steering methods
        % initialize
        function initialize(obj)
            feval(obj.oMexHost,"preciceGateway",uint8(10));
        end
        
        % advance
        function advance(obj,dt)
            feval(obj.oMexHost,"preciceGateway",uint8(11),dt);
        end
        
        % finalize
        function finalize(obj)
            feval(obj.oMexHost,"preciceGateway",uint8(12));
        end
        
        %% Status queries
        % getMeshDimensions
        function dims = getMeshDimensions(obj,meshName)
            if ischar(meshName)
                meshName = string(meshName);
            end
            dims = feval(obj.oMexHost,"preciceGateway",uint8(20),meshName);
        end
        
        % getDataDimensions
        function dims = getDataDimensions(obj,meshName,dataName)
            if ischar(meshName)
                meshName = string(meshName);
            end
            if ischar(dataName)
                dataName = string(dataName);
            end
            dims = feval(obj.oMexHost,"preciceGateway",uint8(21),meshName,dataName);
        end
        
        % isCouplingOngoing
        function bool = isCouplingOngoing(obj)
            bool = feval(obj.oMexHost,"preciceGateway",uint8(22));
        end
        
        % isTimeWindowComplete
        function bool = isTimeWindowComplete(obj)
            bool = feval(obj.oMexHost,"preciceGateway",uint8(23));
        end

        % getMaxTimeStepSize
        function dt = getMaxTimeStepSize(obj)
            dt = feval(obj.oMexHost,"preciceGateway",uint8(24));
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
            bool = feval(obj.oMexHost,"preciceGateway",uint8(26));
        end

        % requiresMeshConnectivityFor
        function bool = requiresMeshConnectivityFor(obj,meshName)
            if ischar(meshName)
                meshName = string(meshName);
            end
            bool = feval(obj.oMexHost,"preciceGateway",uint8(42),meshName);
        end
        
        % setMeshVertex
        function vertexId = setMeshVertex(obj,meshName,position)
            if ischar(meshName)
                meshName = string(meshName);
            end
            vertexId = feval(obj.oMexHost,"preciceGateway",uint8(43),meshName,position);
        end
        
        % setMeshVertices
        function vertexIds = setMeshVertices(obj,meshName,positions)
            if ischar(meshName)
                meshName = string(meshName);
            end
            obj.checkDimensions(size(positions, 1), obj.getDimensions())
            inSize = size(positions,2);
            vertexIds = feval(obj.oMexHost,"preciceGateway",uint8(44),meshName,int32(inSize),positions);
        end

        % getMeshVertexSize
        function vertexId = getMeshVertexSize(obj,meshName)
            if ischar(meshName)
                meshName = string(meshName);
            end
            vertexId = feval(obj.oMexHost,"preciceGateway",uint8(45),meshName);
        end
        
        % setMeshEdge
        function edgeID = setMeshEdge(obj, meshName, firstVertexID, secondVertexID)
            if ischar(meshName)
                meshName = string(meshName);
            end
            edgeID = feval(obj.oMexHost,"preciceGateway",uint8(46),meshName,int32(firstVertexID),int32(secondVertexID));
        end

        % setMeshEdges
        function edgeIDs = setMeshEdges(obj, meshName, vertices)
            if ischar(meshName)
                meshName = string(meshName);
            end
            obj.checkDimensions(size(vertices,1), 2)
            inSize = size(vertices,2);
            edgeIDs = feval(obj.oMexHost,"preciceGateway",uint8(47),meshName,int32(inSize),vertices);
        end

        % setMeshTriangle
        function setMeshTriangle(obj, meshName, firstVertexID, secondVertexID, thirdVertexID)
            if ischar(meshName)
                meshName = string(meshName);
            end
            feval(obj.oMexHost,"preciceGateway",uint8(48),meshName,int32(firstVertexID),int32(secondVertexID),int32(thirdVertexID));
        end

        % setMeshTriangles
        function setMeshTriangles(obj, meshName, vertices)
            obj.checkDimensions(size(vertices,1), 3)
            if ischar(meshName)
                meshName = string(meshName);
            end
            feval(obj.oMexHost,"preciceGateway",uint8(49),meshName,vertices);
        end
        
        % setMeshQuad
        function setMeshQuad(obj, meshName, firstVertexID, secondVertexID, thirdVertexID, fourthVertexID)
            if ischar(meshName)
                meshName = string(meshName);
            end
            feval(obj.oMexHost,"preciceGateway",uint8(50),meshName,int32(firstVertexID),int32(secondVertexID),int32(thirdVertexID),int32(fourthVertexID));
        end

        % setMeshQuads
        function setMeshQuads(obj, meshName, vertices)
            if ischar(meshName)
                meshName = string(meshName);
            end
            obj.checkDimensions(size(vertices,1), 4)
            feval(obj.oMexHost,"preciceGateway",uint8(51),meshName,vertices);
        end

        % setMeshTetrahedron
        function setMeshTetrahedron(obj, meshName, firstVertexID, secondVertexID, thirdVertexID, fourthVertexID)
            if ischar(meshName)
                meshName = string(meshName);
            end
            feval(obj.oMexHost,"preciceGateway",uint8(52),meshName,int32(firstVertexID),int32(secondVertexID),int32(thirdVertexID),int32(fourthVertexID));
        end

        % setMeshTetrahedra
        function setMeshTetrahedra(obj, meshName, vertices)
            obj.checkDimensions(size(vertices,1), 4)
            if ischar(meshName)
                meshName = string(meshName);
            end
            feval(obj.oMexHost,"preciceGateway",uint8(53),meshName,vertices);
        end


        %% Data Access
        % writeData
        function writeData(obj,meshName,dataName,valueIndices,values)
            if ~isa(valueIndices,'int32')
                warning('valueIndices should be allocated as int32 to prevent copying.');
                valueIndices = int32(valueIndices);
            end
            if ischar(meshName)
                meshName = string(meshName);
            end
            if ischar(dataName)
                dataName = string(dataName);
            end

            obj.checkDimensions(size(values, 2), inSize)
            obj.checkDimensions(size(values, 1), obj.getDimensions())
            feval(obj.oMexHost,"preciceGateway",uint8(60),meshName,dataName,valueIndices,values);
        end
        
        % readData
        function values = readData(obj,meshName,dataName,valueIndices,relativeReadTime)
            if ~isa(valueIndices,'int32')
                warning('valueIndices should be allocated as int32 to prevent copying.');
                valueIndices = int32(valueIndices);
            end
            if ischar(meshName)
                meshName = string(meshName);
            end
            if ischar(dataName)
                dataName = string(dataName);
            end
            inSize = length(valueIndices);
            values = feval(obj.oMexHost,"preciceGateway",uint8(61),meshName,dataName,int32(inSize),valueIndices,relativeReadTime);
        end

        % requiresGradientDataFor
        function bool = requiresGradientDataFor(obj,meshName,dataName)
            if ischar(meshName)
                meshName = string(meshName);
            end
            if ischar(dataName)
                dataName = string(dataName);
            end
            bool = feval(obj.oMexHost,"preciceGateway",uint8(62),meshName,dataName);
        end

        % writeGradientData
        function writeGradientData(obj, meshName, dataName, valueIndices, gradientValues)
            if ~isa(valueIndices, 'int32')
                warning('valueIndices should be allocated as int32 to prevent copying.');
                valueIndices = int32(valueIndices);
            end
            if ischar(meshName)
                meshName = string(meshName);
            end
            if ischar(dataName)
                dataName = string(dataName);
            end
            obj.checkDimensions(size(gradientValues, 2), inSize)
            obj.checkDimensions(size(gradientValues, 1), obj.getDimensions() * obj.getDimensions())
            feval(obj.oMexHost, "preciceGateway", uint8(63),meshName,dataName,valueIndices,gradientValues);
        end

        % setMeshAccessRegion
        function setMeshAccessRegion(meshName, boundingBox)
            if ischar(meshName)
                meshName = string(meshName);
            end
            feval(obj.oMexHost,"preciceGateway",uint8(64),meshName,boundingBox);
        end

        % getMeshVertexIDsAndCoordinates
        function [vertices, outIDs] = getMeshVertexIDsAndCoordinates(meshName)
            if ischar(meshName)
                meshName = string(meshName);
            end
            inSize = getMeshVertexSize(meshName);
            [vertices,outIDs] = feval(obj.oMexHost,"preciceGateway",uint8(65),meshName,int32(inSize));
        end

        %% Helper functions
        % Check for dxn convention
        function checkDimensions(obj, a, b)
            assert(a ==  b, 'The shape of the matrices must be [dim numVertices], where dim is the problem dimension');
        end
    end
end
