

DAQIOTABLE["AbstractInputDev"] = InputDev
DAQIOTABLE["InputDev"] = InputDev
DAQIOTABLE["DeviceSet"] = DeviceSet


function daqsave(h, dev::AbstractInputDev, name; version=1)
    g = create_group(h, name)

    attributes(g)["__DAQVERSION__"] = 1
    attributes(g)["__DAQCLASS__"] = ["AbstractInputDev", "InputDev"]

    g["__devname__"] = devname(dev)
    g["__devtype__"] = devtype(dev)

    TDev = typeof(dev)
    haschans = 0
    if hasfield(TDev, :chans) && !isnothing(dev.chans)
        daqsave(g, dev.chans, "chans")
        haschans = 1
    end
    g["__haschans__"] = haschans
            
    hasconfig = 0
    if hasfield(TDev, :config) && !isnothing(dev.config)
        daqsave(g, dev.config, "config")
        hasconfig = 1
    end
    g["__hasconfig__"] = hasconfig
    return
end

function daqload(::Type{InputDev}, h)
        # Is this actually something related to DAQHDF5?
    "__DAQVERSION__" ∉ keys(attributes(h)) &&
        DAQIOTypeError("No __DAQVERSION__ flag found while trying to read InputDev")

    # Are we reading the correct version?
    ver = read(attributes(h)["__DAQVERSION__"])[begin]
    if ver != 1
        throw(DAQIOVersionError("Error when reading `InputDev`. Version 1 expected. Got $ver", "InputDev", ver))
    end

    _type_ = read(attributes(h)["__DAQCLASS__"])
    if _type_[begin] != "AbstractInputDev"
        throw(DAQIOTypeError("Type error: expected `AbstractInputDev` got $_type_ "))
    end

    devname = read(h["__devname__"])[begin]
    devtype = read(h["__devtype__"])[begin]
    haschans = read(h["__haschans__"])[begin]
    if haschans > 0
        chans = daqload(h["chans"])
    else
        chans = nothing
    end
    hasconfig = read(h["__hasconfig__"])
    if hasconfig > 0
        config = daqload(h["config"])
    else
        config = nothing
    end
    
    return InputDev(devname, devtype, chans, config)
end

function daqsave(h, dev::DeviceSet, name; version=1)
    g = create_group(h, name)

    attributes(g)["__DAQVERSION__"] = 1
    attributes(g)["__DAQCLASS__"] = ["AbstractInputDev", "DeviceSet"]

    g["__devname__"] = devname(dev)
    g["__devtype__"] = "DeviceSet"

    g["__devices__"] = collect(devname.(dev.devices))
    g["iref"] = dev.iref
    
    for d in dev.devices
        daqsave(g, d, devname(d), version=1)
    end
        
end

function daqload(::Type{DeviceSet}, h)

    # Is this actually something related to DAQHDF5?
    "__DAQVERSION__" ∉ keys(attributes(h)) &&
        DAQIOTypeError("No __DAQVERSION__ flag found while trying to read DevicSet")

    # Are we reading the correct version?
    ver = read(attributes(h)["__DAQVERSION__"])[begin]
    if ver != 1
        throw(DAQIOVersionError("Error when reading `DeviceSet`. Version 1 expected. Got $ver", "DeviceSet", ver))
    end

    _type_ = read(attributes(h)["__DAQCLASS__"])
    if _type_[end] != "DeviceSet"
        throw(DAQIOTypeError("Type error: expected `DeviceSet` got $_type_ "))
    end

    devname = read(h["__devname__"])[begin]
    devtype = read(h["__devtype__"])[begin]

    devices = read(h["__devices__"])

    iref = read(h["iref"])
    
    idevs = AbstractInputDev[]

    for dname in devices
        push!(idevs, daqload(h[dname]))
    end

    return DeviceSet(devname, idevs, iref)
    
    
end


                 
