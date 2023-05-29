// Gateway MexFunction object
#include "mex.hpp"
#include "mexAdapter.hpp"
#include <iostream>
#include <sstream>
#include <string_view>
#include "precice/Participant.hpp"

using namespace matlab::data;
using matlab::mex::ArgumentList;
using namespace precice;

enum class FunctionID {
    _constructor_ = 0,
    _destructor_ = 1,
    
    initialize = 10,
    advance = 11,
    finalize = 12,
    
    getMeshDimensions = 20,
    getDataDimensions = 21,
    isCouplingOngoing = 22,
    isTimeWindowComplete = 23,
    getMaxTimeStepSize = 24,
    requiresInitialData = 25,
    requiresReadingCheckpoint = 26,
    requiresWritingCheckpoint = 27,
    
    hasMesh = 40,
    hasData = 41,
    requiresMeshConnectivityFor = 42,
    setMeshVertex = 43,
    setMeshVertices = 44,
    getMeshVertexSize = 45,
    setMeshEdge = 46,
    setMeshEdges = 47,
    setMeshTriangle = 48,
    setMeshTriangles = 49,
    setMeshQuad = 50,
    setMeshQuads = 51,
    setMeshTetrahedron = 52,
    setMeshTetrahedra = 53,
    
    writeData = 60,
    readData = 61,
    requiresGradientDataFor = 62,
    writeBlockVectorGradientData = 63,
    setMeshAccessRegion = 64,
    getMeshVerticesAndIDs = 65,
};


std::string convertToString(const matlab::data::Array& arr) {
    matlab::data::TypedArray<MATLABString> in1 = arr;
    std::string participantName = in1[0];
    return participantName;
}

class MexFunction: public matlab::mex::Function {
private:
    Participant* interface;
    ArrayFactory factory;
    bool constructed;
    std::shared_ptr<matlab::engine::MATLABEngine> matlabPtr = getEngine();
    
    void myMexPrint(const std::string text) {
        matlabPtr->feval(u"fprintf",0,std::vector<Array>({factory.createScalar(text)}));
    }

public:
    MexFunction(): constructed{false}, factory{}, interface{NULL} {}

    void operator()(ArgumentList outputs, ArgumentList inputs) {
        // Get the function ID from the input
        TypedArray<uint8_t> functionIDArray = inputs[0];
        FunctionID functionID = static_cast<FunctionID>(static_cast<int>(functionIDArray[0]));
        
        // Abort if constructor was not called before, or if constructor 
        // was called on an existing participant
        if (functionID==FunctionID::_constructor_ && constructed) {
            myMexPrint("Constructor was called but interface is already constructed.");
            return;
        }
        if (!constructed && functionID!=FunctionID::_constructor_) {
            myMexPrint("Interface was not constructed before.");
            return;
        }

        switch (functionID) {
            // 0-9: Construction and Configuration
            // 10-19: Steering
            // 20-29: Status Queries
            // 30-39: Action Methods
            // 40-59: Mesh Access
            // 60-79: Data Access
            case FunctionID::_constructor_:
            {
                std::string participantName = convertToString(inputs[1]);
                std::string configFileName = convertToString(inputs[2]);
                const TypedArray<int32_t> procIndex = inputs[3];
                const TypedArray<int32_t> procSize = inputs[4];
                interface = new Participant(participantName,configFileName,procIndex[0],procSize[0]);
                constructed = true;
                break;
            }
            case FunctionID::_destructor_:
            {
                delete interface;
                constructed = false;
                break;
            }
            case FunctionID::initialize:
            {
                interface->initialize();
                break;
            }
            case FunctionID::advance:
            {
                const TypedArray<double> dt_old = inputs[1];
                interface->advance(dt_old[0]);
                break;
            }
            case FunctionID::finalize:
            {
                interface->finalize();
                break;
            }
            
            case FunctionID::getMeshDimensions:
            {
                int dims = interface->getMeshDimensions();
                outputs[0] = factory.createArray<uint8_t>({1,1}, {(uint8_t) dims});
                break;
            }
            case FunctionID::getDataDimensions:
            {
                const std::string meshName = convertToString(inputs[1]);
                const std::string dataName = convertToString(inputs[2]);
                int dims = interface->getDataDimensions(meshName, dataName);
                outputs[0] = factory.createArray<uint8_t>({1,1}, {(uint8_t) dims});
                break;
            }
            case FunctionID::isCouplingOngoing:
            {
                bool result = interface->isCouplingOngoing();
                outputs[0] = factory.createArray<bool>({1,1}, {result});
                break;
            }
            case FunctionID::isTimeWindowComplete:
            {
                bool result = interface->isTimeWindowComplete();
                outputs[0] = factory.createArray<bool>({1,1}, {result});
                break;
            }
            case FunctionID::getMaxTimeStepSize:
            {
                double result = interface->getMaxTimeStepSize();
                outputs[0] = factory.createArray<double>({1,1}, {result});
                break;
            }
            case FunctionID::requiresInitialData:
            {
                bool result = interface->requiresInitialData();
                outputs[0] = factory.createArray<bool>({1,1}, {result});
                break;
            }
            case FunctionID::requiresReadingCheckpoint:
            {
                bool result = interface->requiresReadingCheckpoint();
                outputs[0] = factory.createArray<bool>({1,1}, {result});
                break;
            }
            case FunctionID::requiresWritingCheckpoint:
            {
                bool result = interface->requiresWritingCheckpoint();
                outputs[0] = factory.createArray<bool>({1,1}, {result});
                break;
            }
            case FunctionID::hasMesh:
            {
                const std::string meshName = convertToString(inputs[1]);
                bool output = interface->hasMesh(meshName);
                outputs[0] = factory.createScalar<bool>(output);
                break;
            }
            case FunctionID::hasData:
            {
                const std::string meshName = convertToString(inputs[1]);
                const std::string dataName = convertToString(inputs[2]);
                bool output = interface->hasData(meshName,dataName);
                outputs[0] = factory.createScalar<bool>(output);
                break;
            }
            case FunctionID::requiresMeshConnectivityFor:
            {
                const std::string meshName = convertToString(inputs[1]);
                bool output = interface->requiresMeshConnectivityFor(meshName);
                outputs[0] = factory.createScalar<bool>(output);
                break;
            }
            case FunctionID::setMeshVertex:
            {
                const std::string meshName = convertToString(inputs[1]);
                const TypedArray<double> position = inputs[2];
                int id = interface->setMeshVertex(meshName,&*position.begin());
                outputs[0] = factory.createScalar<int32_t>(id);
                break;
            }
            case FunctionID::setMeshVertices:
            {
                const std::string meshName = convertToString(inputs[1]);
                const TypedArray<int32_t> size = inputs[2];
                const TypedArray<double> positions = inputs[3];
                buffer_ptr_t<int32_t> ids_ptr = factory.createBuffer<int32_t>(size[0]);
                int32_t* ids = ids_ptr.get();
                interface->setMeshVertices(meshName,size[0],&*positions.begin(),ids);
                // problem: size[0] is not of type size_t
                outputs[0] = factory.createArrayFromBuffer<int32_t>({1,size[0]}, std::move(ids_ptr));
                break;
            }
            case FunctionID::getMeshVertexSize:
            {
                const std::string meshName = convertToString(inputs[1]);
                int size = interface->getMeshVertexSize(meshName);
                outputs[0] = factory.createScalar<int32_t>(size);
                break;
            }
            case FunctionID::setMeshEdge:
            {
                const std::string meshName = convertToString(inputs[1]);
                const TypedArray<int32_t> firstVertexID = inputs[2];
                const TypedArray<int32_t> secondVertexID = inputs[3];
                interface->setMeshEdge(meshName,firstVertexID[0],secondVertexID[0]);
                break;
            }
            case FunctionID::setMeshEdges:
            {
                const std::string meshName = convertToString(inputs[1]);
                const TypedArray<int32_t> size = inputs[2];
                const TypedArray<int32_t> vertices = inputs[3];
                interface->setMeshEdges(meshName,size[0],&*vertices.begin());
                break;
            }
            case FunctionID::setMeshTriangle:
            {
                const std::string meshName = convertToString(inputs[1]);
                const TypedArray<int32_t> firstEdgeID = inputs[2];
                const TypedArray<int32_t> secondEdgeID = inputs[3];
                const TypedArray<int32_t> thirdEdgeID = inputs[4];
                interface->setMeshTriangle(meshName,firstEdgeID[0],secondEdgeID[0],thirdEdgeID[0]);
                break;
            }
            case FunctionID::setMeshTriangles:
            {
                const std::string meshName = convertToString(inputs[1]);
                const TypedArray<int32_t> size = inputs[2];
                const TypedArray<int32_t> vertices = inputs[3];
                interface->setMeshTriangles(meshName,size[0],&*vertices.begin());
                break;
            }
            case FunctionID::setMeshQuad:
            {
                const std::string meshName = convertToString(inputs[1]);
                const TypedArray<int32_t> firstEdgeID = inputs[2];
                const TypedArray<int32_t> secondEdgeID = inputs[3];
                const TypedArray<int32_t> thirdEdgeID = inputs[4];
                const TypedArray<int32_t> fourthEdgeID = inputs[5];
                interface->setMeshQuad(meshName,firstEdgeID[0],secondEdgeID[0],thirdEdgeID[0],fourthEdgeID[0]);
                break;
            }
            case FunctionID::setMeshQuads:
            {
                const std::string meshName = convertToString(inputs[1]);
                const TypedArray<int32_t> size = inputs[2];
                const TypedArray<int32_t> vertices = inputs[3];
                interface->setMeshQuads(meshName,size[0],&*vertices.begin());
                break;
            }
            case FunctionID::setMeshTetrahedron:
            {
                const std::string meshName = convertToString(inputs[1]);
                const TypedArray<int32_t> firstTriangleID = inputs[2];
                const TypedArray<int32_t> secondTriangleID = inputs[3];
                const TypedArray<int32_t> thirdTriangleID = inputs[4];
                const TypedArray<int32_t> fourthTriangleID = inputs[5];
                interface->setMeshTetrahedron(meshName,firstTriangleID[0],secondTriangleID[0],thirdTriangleID[0],fourthTriangleID[0]);
                break;
            }
            case FunctionID::setMeshTetrahedra:
            {
                const std::string meshName = convertToString(inputs[1]);
                const TypedArray<int32_t> size = inputs[2];
                const TypedArray<int32_t> vertices = inputs[3];
                interface->setMeshTetrahedra(meshName,size[0],&*vertices.begin());
                break;
            }
            case FunctionID::writeData:
            {
                const std::string meshName = convertToString(inputs[1]);
                const std::string dataName = convertToString(inputs[2]);
                const TypedArray<int32_t> size = inputs[3];
                const TypedArray<int32_t> vertexIDs = inputs[4];
                const TypedArray<double> values = inputs[5];
                interface->writeData(meshName,dataName,size[0],&*vertexIDs.begin(),&*values.begin());
                break;
            }
            case FunctionID::readData:
            {
                const std::string meshName = convertToString(inputs[1]);
                const std::string dataName = convertToString(inputs[2]);
                const TypedArray<int32_t> size = inputs[3];
                const TypedArray<int32_t> vertexIDs = inputs[4];
                size_t dim = interface->getDimensions();
                buffer_ptr_t<double> values_ptr = factory.createBuffer<double>(size[0]*dim);
                double* values = values_ptr.get();
                interface->readData(meshName,dataName,size[0],&*vertexIDs.begin(),values);
                outputs[0] = factory.createArrayFromBuffer<double>({dim,size[0]}, std::move(values_ptr));
                break;
            }
            case FunctionID::requiresGradientDataForBlock:
            {
                const std::string meshName = convertToString(inputs[1]);
                const std::string dataName = convertToString(inputs[2]);
                bool requiresGradientData = interface->requiresGradientDataForBlock(meshName,dataName);
                outputs[0] = factory.createScalar<bool>(requiresGradientData);
                break;
            }
            case FunctionID::writeBlockVectorGradientData:
            {
                const std::string meshName = convertToString(inputs[1]);
                const std::string dataName = convertToString(inputs[2]);
                const TypedArray<int32_t> size = inputs[3];
                const TypedArray<int32_t> vertexIDs = inputs[4];
                const TypedArray<double> gradientValues = inputs[5];
                interface->writeBlockVectorGradientData(meshName,dataName, size[0], &*vertexIDs.begin(), &*gradientValues.begin());
                break;
            }
            case FunctionID::setMeshAccessRegion:
            {
                const std::string meshName = convertToString(inputs[1]);
                const TypedArray<double> boundingBox = inputs[2];
                interface->setMeshAccessRegion(meshName,&*boundingBox.begin());
                break;
            }
            case FunctionID::getMeshVerticesAndIDs:
            {
                const std::string meshName = convertToString(inputs[1]);
                const TypedArray<int32_t> size = inputs[2];
                buffer_ptr_t<int32_t> ids_ptr = factory.createBuffer<int32_t>(size[0]);
                int32_t* ids = ids_ptr.get();
                buffer_ptr_t<double> positions_ptr = factory.createBuffer<double>(size[0]);
                double* positions = positions_ptr.get();
                interface->getMeshVerticesAndIDs(meshName,size[0],ids,positions);
                outputs[0] = factory.createArrayFromBuffer<double>({1,size[0]}, std::move(positions_ptr));
                outputs[1] = factory.createArrayFromBuffer<int32_t>({1,size[0]}, std::move(ids_ptr));
                break;
            } 

            default:
                myMexPrint("An unknown ID was passed.");
                return;
        }
        // Do error handling
        // myMexPrint("A problem occurred while executing the function.");
    }
};
