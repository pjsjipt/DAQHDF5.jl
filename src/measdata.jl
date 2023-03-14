
# Reading MeasData objects. For now, we only read matrix data

DAQIOTABLE["MeasData"] = MeasData

function daqsave(h, x::MeasData, name; version=1)

    g = create_group(h, name)

    attributes(g)["__DAQVERSION__"] = 1
    attributes(g)["__DAQCLASS__"] = ["AbstractMeasData", "MeasData"]

    g["__devname__"] = x.devname
    g["__devtype__"] = x.devtype

    # Sampling infor
    daqsave(g, x.sampling, "sampling", version=version)

    # Saving data
    g["data"] = x.data
    g["units"] = x.units
    
    #Saving channel info
    daqsave(g, x.chans, "channels", version=version)
    
    return
    
    
end


function daqload(::Type{MeasData}, h)

    # Is this actually something related to DAQHDF5?
    "__DAQVERSION__" ∉ keys(attributes(h)) &&
        DAQIOTypeError("No __DAQVERSION__ flag found while trying to read DaqConfig")

    # Are we reading the correct version?
    ver = readelem(attributes(h)["__DAQVERSION__"])
    if ver != 1
        throw(DAQIOVersionError("Error when reading `MeasData`. Version 1 expected. Got $ver", "MeasData", ver))
    end

    # Check if we are reading an actual DaqConfig
    _type_ = read(attributes(h)["__DAQCLASS__"])
    if _type_[end] != "MeasData"
        throw(DAQIOTypeError("Type error: expected `MeasData` got $_type_ "))
    end


    devname = readelem(h["__devname__"])
    devtype = readelem(h["__devtype__"])

    # Read sampling info
    sampling = daqload(h["sampling"])
    # Read data
    data = read(h["data"])
    units = read(h["units"])
    
    # Read Channel Info
    chans = daqload(h["channels"])

    return MeasData(devname, devtype, sampling, data, chans, units)
    
    
end


DAQIOTABLE["MeasDataSet"] = MeasDataSet

    
function daqsave(h, x::MeasDataSet, name; version=1)
    
    g = create_group(h, name)

    attributes(g)["__DAQVERSION__"] = 1
    attributes(g)["__DAQCLASS__"] = ["AbstractMeasData", "MeasDataSet"]

    g["__devname__"] = x.devname
    g["__devtype__"] = x.devtype
    g["__time__"] = x.time.instant.periods.value

    # Get the names of each individual data set:
    g["__devlist__"] = collect(devname.(x.data))

    # Now will save each individual data set
    for devdata in x.data
        daqsave(g, devdata, devname(devdata); version=1)
    end
    
end


function daqload(::Type{MeasDataSet}, h)

    # Is this actually something related to DAQHDF5?
    "__DAQVERSION__" ∉ keys(attributes(h)) &&
        DAQIOTypeError("No __DAQVERSION__ flag found while trying to read DaqConfig")

    # Are we reading the correct version?
    ver = readelem(attributes(h)["__DAQVERSION__"])
    if ver != 1
        throw(DAQIOVersionError("Error when reading `MeasData`. Version 1 expected. Got $ver", "MeasData", ver))
    end

    # Check if we are reading an actual DaqConfig
    _type_ = read(attributes(h)["__DAQCLASS__"])
    if _type_[end] != "MeasDataSet"
        throw(DAQIOTypeError("Type error: expected `DaqChannels` got $_type_ "))
    end


    devname = readelem(h["__devname__"])
    devtype = readelem(h["__devtype__"])
    ms = read(h["__time__"])[begin]
    t = DateTime(Dates.UTInstant{Millisecond}(Millisecond(UInt64(ms))))

    devices = read(h["__devlist__"])
    data = [daqload(h[dev]) for dev in devices]
    return MeasDataSet(devname, devtype, t, data)
end

