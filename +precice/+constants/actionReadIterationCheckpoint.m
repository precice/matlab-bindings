function result = actionReadIterationCheckpoint()
    persistent readIterationCheckpoint;
    if isempty(readIterationCheckpoint)
        readIterationCheckpoint = preciceGateway(uint8(2));
    end
    result = readIterationCheckpoint;
end