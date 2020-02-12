function result = getVersionInformation()
    persistent versionInformation;
    if isempty(versionInformation)
        versionInformation = preciceGateway(uint8(0));
    end
    result = versionInformation;
end