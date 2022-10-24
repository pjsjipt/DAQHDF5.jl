# Saving and loading of DaqChannels objects

DAQIOTABLE["DaqChannels"] = DaqChannels

function daqsave(h, c::DaqChannels, name=""; version=1)

    if name==""
        name = devname(c)
    end

    g = create_group(h, name)

    attributes(g)["__DAQVERSION__"] = 1
    attributes(g)["__DAQCLASS__"] = ["AbstractDaqChannels", "DaqChannels"]

    g["__devname__"] = c.devname
    g["__devtype__"] = c.devtype

    g["channels"] = daqchannels(c)

    # The physchans field and units fields hava parametric types.
    # If these types are something handled well by HDF5.jl, ok
    # Otherwise, specific methods should be implemented
    if isa(c.physchans, AbstractVector)
        phch = collect(c.physchans)
    else
        phch = c.physchans  # Let's hope this works. I really don't know...
    end
    if isa(c.units, AbstractVector)
        units = collect(c.units)
    else
        units = c.units  # Let's hope this works. I really don't know...
    end
    
    g["physchans"] = phch
    g["units"] = units

    return
end


function daqload(::Type{DaqChannels}, h)

    # Is this actually something related to DAQHDF5?
    "__DAQVERSION__" ∉ keys(attributes(h)) &&
        DAQIOTypeError("No __DAQVERSION__ flag found while trying to read DaqConfig")

    # Are we reading the correct version?
    ver = readelem(attributes(h)["__DAQVERSION__"])
    if ver != 1
        throw(DAQIOVersionError("Error when reading `DaqConfig`. Version 1 expected. Got $ver", "DaqConfig", ver))
    end

    # Check if we are reading an actual DaqConfig
    _type_ = read(attributes(h)["__DAQCLASS__"])
    if _type_[end] != "DaqChannels"
        throw(DAQIOTypeError("Type error: expected `DaqChannels` got $_type_ "))
    end

    # Everything appears to be ok!
    devname = readelem(h["__devname__"])
    devtype = readelem(h["__devtype__"])
    chans = read(h["channels"])
    
    # Let's hope this is enough
    physchans = read(h["physchans"])
    units = read(h["units"])
    return DaqChannels(devname, devtype, chans, units, physchans)
    
end
