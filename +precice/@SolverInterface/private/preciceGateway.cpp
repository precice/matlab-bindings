// Gateway MexFunction object
#include "mex.hpp"
#include "mexAdapter.hpp"
#include <iostream>
#include <sstream>
#include "precice/SolverInterface.hpp"

using namespace matlab::data;
using matlab::mex::ArgumentList;
using namespace precice;

enum class FunctionID {
    _constructor_ = 0,
    _destructor_ = 1,
    
    initialize = 10,
    initializeData = 11,
    advance = 12,
    finalize = 13,
    
    getDimensions = 20,
    isCouplingOngoing = 21,
    isReadDataAvailable = 22,
    isWriteDataRequired = 23,
    isTimeWindowComplete = 24,
    hasToEvaluateSurrogateModel = 25,
    hasToEvaluateFineModel = 26,
    getVersionInformation = 27,
    
    isActionRequired = 30,
    markActionFulfilled = 31,
    
    hasMesh = 40,
    getMeshID = 41,
    getMeshHandle = 43,
    setMeshVertex = 44,
    getMeshVertexSize = 45,
    setMeshVertices = 46,
    getMeshVertices = 47,
    getMeshVertexIDsFromPositions = 48,
    setMeshEdge = 49,
    setMeshTriangle = 50,
    setMeshTriangleWithEdges = 51,
    setMeshQuad = 52,
    setMeshQuadWithEdges = 53,
    isMeshConnectivityRequired = 54,
    setMeshAccessRegion = 55,
    getMeshVerticesAndIDs = 56,
    
    hasData = 60,
    getDataID = 61,
    mapReadDataTo = 62,
    mapWriteDataFrom = 63,
    writeBlockVectorData = 64,
    writeVectorData = 65,
    writeBlockScalarData = 66,
    writeScalarData = 67,
    readBlockVectorData = 68,
    readVectorData = 69,
    readBlockScalarData = 70,
    readScalarData = 71,

    isGradientDataRequired = 72,
    writeBlockVectorGradientData = 73,
    writeVectorGradientData = 74,
    writeBlockScalarGradientData = 75,
    writeScalarGradientData = 76,
};

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
                const StringArray solverName = inputs[1];
                const StringArray configFileName = inputs[2];
                const TypedArray<int32_t> procIndex = inputs[3];
                const TypedArray<int32_t> procSize = inputs[4];
                interface = new SolverInterface(solverName[0],configFileName[0],procIndex[0],procSize[0]);
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
            case FunctionID::initializeData: //initializeData
            {
                interface->initializeData();
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
                const StringArray meshName = inputs[1];
                bool output = interface->hasMesh(meshName[0]);
                outputs[0] = factory.createScalar<bool>(output);
                break;
            }            
            case FunctionID::setMeshVertex:
            {
                const StringArray meshName = inputs[1];
                const TypedArray<double> position = inputs[2];
                int id = interface->setMeshVertex(meshName[0],&*position.begin());
                outputs[0] = factory.createScalar<int32_t>(id);
                break;
            }
            case FunctionID::getMeshVertexSize:
            {
                const StringArray meshName = inputs[1];
                int size = interface->getMeshVertexSize(meshName[0]);
                outputs[0] = factory.createScalar<int32_t>(size);
                break;
            }
            case FunctionID::setMeshVertices:
            {
                const StringArray meshName = inputs[1];
                const TypedArray<int32_t> size = inputs[2];
                const TypedArray<double> positions = inputs[3];
                buffer_ptr_t<int32_t> ids_ptr = factory.createBuffer<int32_t>(size[0]);
                int32_t* ids = ids_ptr.get();
                interface->setMeshVertices(meshName[0],size[0],&*positions.begin(),ids);
                outputs[0] = factory.createArrayFromBuffer<int32_t>({1,size[0]}, std::move(ids_ptr));
                break;
            }
            case FunctionID::setMeshEdge:
            {
                const StringArray meshName = inputs[1];
                const TypedArray<int32_t> firstVertexID = inputs[2];
                const TypedArray<int32_t> secondVertexID = inputs[3];
                int id = interface->setMeshEdge(meshName[0],firstVertexID[0],secondVertexID[0]);
                outputs[0] = factory.createScalar<int32_t>(id);
                break;
            }
            case FunctionID::setMeshTriangle:
            {
                const StringArray meshName = inputs[1];
                const TypedArray<int32_t> firstEdgeID = inputs[2];
                const TypedArray<int32_t> secondEdgeID = inputs[3];
                const TypedArray<int32_t> thirdEdgeID = inputs[4];
                interface->setMeshTriangle(meshName[0],firstEdgeID[0],secondEdgeID[0],thirdEdgeID[0]);
                break;
            }
            case FunctionID::setMeshQuad:
            {
                const StringArray meshName = inputs[1];
                const TypedArray<int32_t> firstEdgeID = inputs[2];
                const TypedArray<int32_t> secondEdgeID = inputs[3];
                const TypedArray<int32_t> thirdEdgeID = inputs[4];
                const TypedArray<int32_t> fourthEdgeID = inputs[5];
                interface->setMeshQuad(meshName[0],firstEdgeID[0],secondEdgeID[0],thirdEdgeID[0],fourthEdgeID[0]);
                break;
            }
            case FunctionID::setMeshAccessRegion:
            {
                const StringArray meshName = inputs[1];
                const TypedArray<double> boundingBox = inputs[2];
                interface->setMeshAccessRegion(meshName[0],&*boundingBox.begin());
                break;
            }
            case FunctionID::getMeshVerticesAndIDs:
            {
                const StringArray meshName = inputs[1];
                const TypedArray<int32_t> size = inputs[2];
                buffer_ptr_t<int32_t> ids_ptr = factory.createBuffer<int32_t>(size[0]);
                int32_t* ids = ids_ptr.get();
                buffer_ptr_t<double> positions_ptr = factory.createBuffer<double>(size[0]);
                double* positions = positions_ptr.get();
                interface->getMeshVertices(meshName[0],size[0],ids,positions);
                outputs[0] = factory.createArrayFromBuffer<double>({1,size[0]}, std::move(positions_ptr));
                outputs[1] = factory.createArrayFromBuffer<int32_t>({1,size[0]}, std::move(ids_ptr));
                break;
            } 
            case FunctionID::hasData:
            {
                const StringArray meshName = inputs[1];
                const StringArray dataName = inputs[2];
                bool output = interface->hasData(dataName[0],meshName[0]);
                outputs[0] = factory.createScalar<bool>(output);
                break;
            }
            case FunctionID::mapWriteDataFrom:
            {
                const TypedArray<int32_t> fromMeshID = inputs[1];
                interface->mapWriteDataFrom(fromMeshName[0]);
                break;
            }
            case FunctionID::writeBlockVectorData:
            {
                const StringArray meshName = inputs[1];
                const StringArray dataName = inputs[2];
                const TypedArray<int32_t> size = inputs[3];
                const TypedArray<int32_t> vertexIDs = inputs[4];
                const TypedArray<double> values = inputs[5];
                interface->writeBlockVectorData(dataID[0],size[0],&*vertexIDs.begin(),&*values.begin());
                break;
            }
            case FunctionID::writeVectorData:
            {
                const StringArray meshName = inputs[1];
                const StringArray dataName = inputs[2];
                const TypedArray<int32_t> valueIndex = inputs[3];
                const TypedArray<double> value = inputs[4];
                interface->writeVectorData(dataID[0],valueIndex[0],&*value.begin());
                break;
            }
            case FunctionID::writeBlockScalarData:
            {
                const StringArray meshName = inputs[1];
                const StringArray dataName = inputs[2];
                const TypedArray<int32_t> size = inputs[3];
                const TypedArray<int32_t> vertexIDs = inputs[4];
                const TypedArray<double> values = inputs[5];
                interface->writeBlockScalarData(dataID[0],size[0],&*vertexIDs.begin(),&*values.begin());
                break;
            }
            case FunctionID::writeScalarData:
            {
                const StringArray meshName = inputs[1];
                const StringArray dataName = inputs[2];
                const TypedArray<int32_t> valueIndex = inputs[3];
                const TypedArray<double> value = inputs[4];
                interface->writeScalarData(dataID[0],valueIndex[0],value[0]);
                break;
            }
            case FunctionID::readBlockVectorData:
            {
                const StringArray meshName = inputs[1];
                const StringArray dataName = inputs[2];
                const TypedArray<int32_t> size = inputs[3];
                const TypedArray<int32_t> vertexIDs = inputs[4];
                int32_t dim = interface->getDimensions();
                buffer_ptr_t<double> values_ptr = factory.createBuffer<double>(size[0]*dim);
                double* values = values_ptr.get();
                interface->readBlockVectorData(dataID[0],size[0],&*vertexIDs.begin(),values);
                outputs[0] = factory.createArrayFromBuffer<double>({dim,size[0]}, std::move(values_ptr));
                break;
            }
            case FunctionID::readVectorData:
            {
                const StringArray meshName = inputs[1];
                const StringArray dataName = inputs[2];
                const TypedArray<int32_t> valueIndex = inputs[3];
                int32_t dim = interface->getDimensions();
                buffer_ptr_t<double> value_ptr = factory.createBuffer<double>(dim);
                double* value = value_ptr.get();
                interface->readVectorData(dataID[0],valueIndex[0],value);
                outputs[0] = factory.createArrayFromBuffer<double>({dim,1}, std::move(value_ptr));
                break;
            }
            case FunctionID::readBlockScalarData:
            {
                const StringArray meshName = std::move(inputs[1]);
                const StringArray dataName = inputs[2];
                const TypedArray<int32_t> size = std::move(inputs[3]);
                const TypedArray<int32_t> valueIndices = std::move(inputs[4]);
                const TypedArray<bool> transpose = std::move(inputs[5]);
                int32_t sizeA, sizeB;
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
                interface->readBlockScalarData(dataID[0],size[0],&*valueIndices.begin(),values);
                outputs[0] = factory.createArrayFromBuffer<double>({sizeA,sizeB}, std::move(values_ptr));
                break;
            }
            case FunctionID::readScalarData:
            {
                const StringArray meshName = inputs[1];
                const StringArray dataName = inputs[2];
                const TypedArray<int32_t> valueIndex = inputs[3];
                double value;
                interface->readScalarData(dataID[0],valueIndex[0],value);
                outputs[0] = factory.createScalar<double>(value);
                break;
            }
            case FunctionID::writeBlockVectorGradientData:
            {
                const StringArray meshName = inputs[1];
                const StringArray dataName = inputs[2];
                const TypedArray<int32_t> size = inputs[3];
                const TypedArray<int32_t> vertexIDs = inputs[4];
                const TypedArray<double> gradientValues = inputs[5];
                interface->writeBlockVectorGradientData(dataID[0], size[0], &*vertexIDs.begin(), &*gradientValues.begin());
                break;
            }
            case FunctionID::writeScalarGradientData:
            {
                const StringArray meshName = inputs[1];
                const StringArray dataName = inputs[2];
                const TypedArray<int32_t> vertexID = inputs[3];
                const TypedArray<double> gradientValues = inputs[4];
                interface->writeScalarGradientData(dataID[0], vertexID[0], &*gradientValues.begin());
                break;
            }
            case FunctionID::writeVectorGradientData:
            {
                const StringArray meshName = inputs[1];
                const StringArray dataName = inputs[2];
                const TypedArray<int32_t> vertexID = inputs[3];
                const TypedArray<double> gradientValues = inputs[4];
                interface->writeVectorGradientData(dataID[0], vertexID[0], &*gradientValues.begin());
                break;
            }
            case FunctionID::writeBlockScalarGradientData:
            {
                const StringArray meshName = inputs[1];
                const StringArray dataName = inputs[2];
                const TypedArray<int32_t> size = inputs[3];
                const TypedArray<int32_t> vertexIDs = inputs[4];
                const TypedArray<double> gradientValues = inputs[5];
                interface->writeBlockScalarGradientData(dataID[0], size[0], &*vertexIDs.begin(), &*gradientValues.begin());
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
