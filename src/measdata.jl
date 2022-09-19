
# Reading MeasData objects. For now, we only read matrix data


function daqsave(h, x::MeasData, name=""; version=1)

    if name==""
        name = devname(x)
    end
    g = create_group(h, name)

    attributes(g)["__DAQVERSION__"] = 1
    attributes(g)["__DAQCLASS__"] = ["AbstractMeasData", "MeasData"]

    g["devname"] = x.devname
    g["devtype"] = x.devtype

    # Sampling infor
    daqsave(g, x.sampling, "sampling", version=version)

    # Saving data
    g["data"] = x.data
    
    #Saving channel info
    daqsave(g, x.chans, "channels", version=version)

    return
    
    
end


function daqload(::Type{MeasData}, h)

    # Is this actually something related to DAQHDF5?
    "__DAQVERSION__" ∉ keys(attributes(h)) &&
        DAQIOTypeError("No __DAQVERSION__ flag found while trying to read DaqConfig")

    # Are we reading the correct version?
    ver = read(attributes(h)["__DAQVERSION__"])[begin]
    if ver != 1
        throw(DAQIOVersionError("Error when reading `MeasData`. Version 1 expected. Got $ver", "MeasData", ver))
    end

    # Check if we are reading an actual DaqConfig
    _type_ = read(attributes(h)["__DAQCLASS__"])
    if _type_[end] != "MeasData"
        throw(DAQIOTypeError("Type error: expected `DaqChannels` got $_type_ "))
    end


    devname = read(h["devname"])[begin]
    devtype = read(h["devtype"])[begin]

    # Read sampling info
    sampling = daqload(AbstractDaqSampling, h["sampling"])

    # Read data
    data = read(h["data"])

    # Read Channel Info
    chans = daqload(DaqChannels, h["channels"])

    return MeasData(devname, devtype, sampling, data, chans)
    
    
end



    
function daqsave(h, x::MeasDataSet, name=""; version=1)

    
end
