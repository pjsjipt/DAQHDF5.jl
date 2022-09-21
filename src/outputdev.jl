

DAQIOTABLE["AbstractOutputDev"] = OutputDev
DAQIOTABLE["OutputDev"] = OutputDev
DAQIOTABLE["OutputDevSet"] = OutputDevSet



function daqsave(h, dev::AbstractOutputDev, name; version=1)
    g = create_group(h, name)

    attributes(g)["__DAQVERSION__"] = 1
    attributes(g)["__DAQCLASS__"] = ["AbstractOutputDev", "OutputDev"]

    g["__devname__"] = devname(dev)
    g["__devtype__"] = devtype(dev)

    g["__axes__"] = axesnames(dev)
    
    # Check if the device has a config field:
    if hasfield(typeof(dev), :config)
        daqsave(g, dev.config, "config")
        g["__hasconfig__"] = 1
    else
        g["__hasconfig__"] = 0
    end
        
end


function daqload(::Type{OutputDev}, h)
    # Is this actually something related to DAQHDF5?
    "__DAQVERSION__" ∉ keys(attributes(h)) &&
        DAQIOTypeError("No __DAQVERSION__ flag found while trying to read OutputDev")

    # Are we reading the correct version?
    ver = read(attributes(h)["__DAQVERSION__"])
    if ver != 1
        throw(DAQIOVersionError("Error when reading `OutputDev`. Version 1 expected. Got $ver", "OutputDev", ver))
    end

    _type_ = read(attributes(h)["__DAQCLASS__"])
    if _type_[end] != "OutputDev"
        throw(DAQIOTypeError("Type error: expected `OutputDev` got $_type_ "))
    end

    devname = read(h["__devname__"])
    devtype = read(h["__devtype__"])

    axes = read(h["__axes__"])
    
    hasconfig = read(h["__hasconfig__"])
    if hasconfig > 0
        config = daqload(h["config"])
    else
        config = DaqConfig(devname, devtype)
    end
    return OutputDev(devname, devtype, axes, config)
    
end



function daqsave(h, dev::OutputDevSet, name; version=1)
    g = create_group(h, name)

    attributes(g)["__DAQVERSION__"] = 1
    attributes(g)["__DAQCLASS__"] = ["AbstractOutputDev", "OutputDevSet"]

    g["__devname__"] = devname(dev)
    g["__devtype__"] = "OutputDevSet"

    g["__axes__"] = collect(axesnames(dev))
    g["__devices__"] = collect(devname.(dev.odev))
    
    for d in dev.odev
        daqsave(g, d, devname(d), version=1)
    end
        
end


function daqload(::Type{OutputDevSet}, h; version=1)
    # Is this actually something related to DAQHDF5?
    "__DAQVERSION__" ∉ keys(attributes(h)) &&
        DAQIOTypeError("No __DAQVERSION__ flag found while trying to read OutputDevSet")

    # Are we reading the correct version?
    ver = read(attributes(h)["__DAQVERSION__"])
    if ver != 1
        throw(DAQIOVersionError("Error when reading `OutputDevSet`. Version 1 expected. Got $ver", "OutputDevSet", ver))
    end

    _type_ = read(attributes(h)["__DAQCLASS__"])
    if _type_[end] != "OutputDevSet"
        throw(DAQIOTypeError("Type error: expected `OutputDevSet` got $_type_ "))
    end

    devname = read(h["__devname__"])
    devtype = read(h["__devtype__"])

    devices = read(h["__devices__"])

    odevs = AbstractOutputDev[]

    for dname in devices
        push!(odevs, daqload(h[dname]))
    end

    return OutputDevSet(devname, odevs)
    
end
