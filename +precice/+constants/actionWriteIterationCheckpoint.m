function result = actionWriteIterationCheckpoint()
    persistent writeIterationCheckpoint;
    if isempty(writeIterationCheckpoint)
        writeIterationCheckpoint = preciceGateway(uint8(1));
    end
    result = writeIterationCheckpoint;
end