# DaqPlan
# Experiment Plan


DAQIOTABLE["DaqPlan"] = AbstractDaqPlan
DAQIOTABLE["AbstractDaqPlan"] = AbstractDaqPlan


function daqsave(h, dev::AbstractDaqPlan, name; version=1)
    g = create_group(h, name)

    attributes(g)["__DAQVERSION__"] = 1
    attributes(g)["__DAQCLASS__"] = ["AbstractDaqPlan", "DaqPlan"]

    g["devname"] = devname(dev)
    g["devtype"] = devtype(dev)
    g["lastpoint"] = lastpoint(dev)
    g["axes"] = axesnames(dev)
    g["avals"] = axesvals(dev)

    daqsave(g, outputdevice(dev), "output_device")
    daqsave(g, planpoints(dev), "points")
    
end

function daqload(::Type{DaqPlan}, h)

    # Is this actually something related to DAQHDF5?
    "__DAQVERSION__" ∉ keys(attributes(h)) &&
        DAQIOTypeError("No __DAQVERSION__ flag found while trying to read `DaqPlan`")

    # Are we reading the correct version?
    ver = readelem(attributes(h)["__DAQVERSION__"])
    if ver != 1
        throw(DAQIOVersionError("Error when reading `DaqPlan`. Version 1 expected. Got $ver", "DaqPlan", ver))
    end
    
    _type_ = read(attributes(h)["__DAQCLASS__"])
    if _type_[end] != "DaqPlan"
        throw(DAQIOTypeError("Type error: expected `DaqPlan` got $_type_ "))
    end

    dname = read(h["devname"])
    dtype = read(h["devtype"])
    
    lastpoint = read(h["lastpoint"])[1]
    axes = read(h["axes"])
    avals = read(h["avals"])
    

    dev = daqload(h["output_device"])
    points = daqload(h["points"])

    return DaqPlan(dname, dtype, lastpoint, false, dev, points, axes, avals)
    
end


