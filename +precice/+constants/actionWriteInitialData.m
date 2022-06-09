function result = actionWriteInitialData()
    persistent writeInitialData;
    if isempty(writeInitialData)
        writeInitialData = preciceGateway(uint8(0));
    end
    result = writeInitialData;
end