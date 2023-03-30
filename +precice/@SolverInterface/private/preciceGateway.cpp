// Gateway MexFunction object
#include "mex.hpp"
#include "mexAdapter.hpp"
#include <iostream>
#include <sstream>
#include <string_view>
#include "precice/SolverInterface.hpp"

using namespace matlab::data;
using matlab::mex::ArgumentList;
using namespace precice;

enum class FunctionID {
    _constructor_ = 0,
    _destructor_ = 1,
    
    initialize = 10,
    advance = 11,
    finalize = 12,
    
    getDimensions = 20,
    isCouplingOngoing = 21,
    isTimeWindowComplete = 22,
    requiresInitialData = 23,
    requiresReadingCheckpoint = 24,
    requiresWritingCheckpoint = 25,
    
    hasMesh = 40,
    requiresMeshConnectivityFor = 41,
    requiresGradientDataFor = 42,
    setMeshVertex = 43,
    getMeshVertexSize = 44,
    setMeshVertices = 45,
    setMeshEdge = 46,
    setMeshEdges = 47,
    setMeshTriangle = 48,
    setMeshTriangles = 49,
    setMeshQuad = 50,
    setMeshQuads = 51,
    setMeshTetrahedron = 52,
    setMeshTetrahedra = 53,
    setMeshAccessRegion = 54,
    getMeshVerticesAndIDs = 55,
    
    hasData = 60,
    writeBlockVectorData = 61,
    writeVectorData = 62,
    writeBlockScalarData = 63,
    writeScalarData = 64,
    readBlockVectorData = 65,
    readVectorData = 66,
    readBlockScalarData = 67,
    readScalarData = 68,
    writeBlockVectorGradientData = 69,
    writeVectorGradientData = 70,
    writeBlockScalarGradientData = 71,
    writeScalarGradientData = 72,
};


std::string convertToString(const matlab::data::Array& arr) {
    matlab::data::TypedArray<MATLABString> in1 = arr;
    std::string solverName = in1[0];
    return solverName;
}

class MexFunction: public matlab::mex::Function {
private:
    SolverInterface* interface;
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
        // was called on an existing solverInterface
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
                std::string solverName = convertToString(inputs[1]);
                std::string configFileName = convertToString(inputs[2]);
                const TypedArray<int32_t> procIndex = inputs[3];
                const TypedArray<int32_t> procSize = inputs[4];
                interface = new SolverInterface(solverName,configFileName,procIndex[0],procSize[0]);
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
                double dt = interface->initialize();
                outputs[0] = factory.createArray<double>({1,1}, {dt});
                break;
            }
            case FunctionID::advance:
            {
                const TypedArray<double> dt_old = inputs[1];
                double dt = interface->advance(dt_old[0]);
                outputs[0] = factory.createArray<double>({1,1}, {dt});
                break;
            }
            case FunctionID::finalize:
            {
                interface->finalize();
                break;
            }
            
            case FunctionID::getDimensions:
            {
                int dims = interface->getDimensions();
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
            case FunctionID::setMeshVertex:
            {
                const std::string meshName = convertToString(inputs[1]);
                const TypedArray<double> position = inputs[2];
                int id = interface->setMeshVertex(meshName,&*position.begin());
                outputs[0] = factory.createScalar<int32_t>(id);
                break;
            }
            case FunctionID::getMeshVertexSize:
            {
                const std::string meshName = convertToString(inputs[1]);
                int size = interface->getMeshVertexSize(meshName);
                outputs[0] = factory.createScalar<int32_t>(size);
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
            case FunctionID::setMeshEdge:
            {
                const std::string meshName = convertToString(inputs[1]);
                const TypedArray<int32_t> firstVertexID = inputs[2];
                const TypedArray<int32_t> secondVertexID = inputs[3];
                interface->setMeshEdge(meshName,firstVertexID[0],secondVertexID[0]);
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
            case FunctionID::hasData:
            {
                const std::string meshName = convertToString(inputs[1]);
                const std::string dataName = convertToString(inputs[2]);
                bool output = interface->hasData(meshName,dataName);
                outputs[0] = factory.createScalar<bool>(output);
                break;
            }
            case FunctionID::writeBlockVectorData:
            {
                const std::string meshName = convertToString(inputs[1]);
                const std::string dataName = convertToString(inputs[2]);
                const TypedArray<int32_t> size = inputs[3];
                const TypedArray<int32_t> vertexIDs = inputs[4];
                const TypedArray<double> values = inputs[5];
                interface->writeBlockVectorData(meshName,dataName,size[0],&*vertexIDs.begin(),&*values.begin());
                break;
            }
            case FunctionID::writeVectorData:
            {
                const std::string meshName = convertToString(inputs[1]);
                const std::string dataName = convertToString(inputs[2]);
                const TypedArray<int32_t> valueIndex = inputs[3];
                const TypedArray<double> value = inputs[4];
                interface->writeVectorData(meshName,dataName,valueIndex[0],&*value.begin());
                break;
            }
            case FunctionID::writeBlockScalarData:
            {
                const std::string meshName = convertToString(inputs[1]);
                const std::string dataName = convertToString(inputs[2]);
                const TypedArray<int32_t> size = inputs[3];
                const TypedArray<int32_t> vertexIDs = inputs[4];
                const TypedArray<double> values = inputs[5];
                interface->writeBlockScalarData(meshName,dataName,size[0],&*vertexIDs.begin(),&*values.begin());
                break;
            }
            case FunctionID::writeScalarData:
            {
                const std::string meshName = convertToString(inputs[1]);
                const std::string dataName = convertToString(inputs[2]);
                const TypedArray<int32_t> valueIndex = inputs[3];
                const TypedArray<double> value = inputs[4];
                interface->writeScalarData(meshName,dataName,valueIndex[0],value[0]);
                break;
            }
            case FunctionID::readBlockVectorData:
            {
                const std::string meshName = convertToString(inputs[1]);
                const std::string dataName = convertToString(inputs[2]);
                const TypedArray<int32_t> size = inputs[3];
                const TypedArray<int32_t> vertexIDs = inputs[4];
                size_t dim = interface->getDimensions();
                buffer_ptr_t<double> values_ptr = factory.createBuffer<double>(size[0]*dim);
                double* values = values_ptr.get();
                interface->readBlockVectorData(meshName,dataName,size[0],&*vertexIDs.begin(),values);
                outputs[0] = factory.createArrayFromBuffer<double>({dim,size[0]}, std::move(values_ptr));
                break;
            }
            case FunctionID::readVectorData:
            {
                const std::string meshName = convertToString(inputs[1]);
                const std::string dataName = convertToString(inputs[2]);
                const TypedArray<int32_t> valueIndex = inputs[3];
                size_t dim = interface->getDimensions();
                buffer_ptr_t<double> value_ptr = factory.createBuffer<double>(dim);
                double* value = value_ptr.get();
                interface->readVectorData(meshName,dataName,valueIndex[0],value);
                outputs[0] = factory.createArrayFromBuffer<double>({dim,1}, std::move(value_ptr));
                break;
            }
            case FunctionID::readBlockScalarData:
            {
                const std::string meshName = convertToString(inputs[1]);
                const std::string dataName = convertToString(inputs[2]);
                const TypedArray<int32_t> size = std::move(inputs[3]);
                const TypedArray<int32_t> valueIndices = std::move(inputs[4]);
                const TypedArray<bool> transpose = std::move(inputs[5]);
                size_t sizeA, sizeB;
                if (transpose[0]) {
                    sizeA = size[0];
                    sizeB = 1;
                }
                else {
                    sizeA = 1;
                    sizeB = size[0];
                }
                buffer_ptr_t<double> values_ptr = factory.createBuffer<double>(size[0]);
                double* values = values_ptr.get();
                interface->readBlockScalarData(meshName,dataName,size[0],&*valueIndices.begin(),values);
                outputs[0] = factory.createArrayFromBuffer<double>({sizeA,sizeB}, std::move(values_ptr));
                break;
            }
            case FunctionID::readScalarData:
            {
                const std::string meshName = convertToString(inputs[1]);
                const std::string dataName = convertToString(inputs[2]);
                const TypedArray<int32_t> valueIndex = inputs[3];
                double value;
                interface->readScalarData(meshName,dataName,valueIndex[0],value);
                outputs[0] = factory.createScalar<double>(value);
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
            case FunctionID::writeScalarGradientData:
            {
                const std::string meshName = convertToString(inputs[1]);
                const std::string dataName = convertToString(inputs[2]);
                const TypedArray<int32_t> vertexID = inputs[3];
                const TypedArray<double> gradientValues = inputs[4];
                interface->writeScalarGradientData(meshName,dataName, vertexID[0], &*gradientValues.begin());
                break;
            }
            case FunctionID::writeVectorGradientData:
            {
                const std::string meshName = convertToString(inputs[1]);
                const std::string dataName = convertToString(inputs[2]);
                const TypedArray<int32_t> vertexID = inputs[3];
                const TypedArray<double> gradientValues = inputs[4];
                interface->writeVectorGradientData(meshName,dataName, vertexID[0], &*gradientValues.begin());
                break;
            }
            case FunctionID::writeBlockScalarGradientData:
            {
                const std::string meshName = convertToString(inputs[1]);
                const std::string dataName = convertToString(inputs[2]);
                const TypedArray<int32_t> size = inputs[3];
                const TypedArray<int32_t> vertexIDs = inputs[4];
                const TypedArray<double> gradientValues = inputs[5];
                interface->writeBlockScalarGradientData(meshName,dataName, size[0], &*vertexIDs.begin(), &*gradientValues.begin());
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
