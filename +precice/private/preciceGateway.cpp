// Gateway MexFunction object
#include "mex.hpp"
#include "mexAdapter.hpp"
#include <iostream>
#include "precice/SolverInterface.hpp"

using namespace matlab::data;
using matlab::mex::ArgumentList;
using namespace precice;

class MexFunction: public matlab::mex::Function {
private:
    ArrayFactory factory;

public:
    void operator()(ArgumentList outputs, ArgumentList inputs) {
        // define the constantID
        TypedArray<uint8_t> functionIDArray = inputs[0];
        int preciceID = functionIDArray[0];
        std::string result;

        // assign
        switch (preciceID) {
            case 0:
                result = getVersionInformation();
                break;
            default:
                std::cout << "MEX precice gateway: An unknown ID was passed." << std::endl;
                return;
        }

        outputs[0] = factory.createCharArray(result);
    }
};
