# Saving and loading of DaqChannels objects


function daqsave(h, c::DaqChannels, name=""; version=1)

    if name==""
        name = devname(c)
    end

    g = create_group(h, name)

    attributes(g)["__VERSION__"] = 1
    attributes(g)["__CLASS__"] = "AbstractDaqChannels"
    attributes(g)["__TYPE__"] = "DaqChannels"

    g["devname"] = c.devname
    g["devtype"] = c.devtype

    g["channels"] = daqchannels(c)

    # The physchans field and units fields hava parametric types.
    # If these types are something handled well by HDF5.jl, ok
    # Otherwise, specific methods should be implemented

    g["physchans"] = c.physchans
    g["units"] = c.units

    return
end


function daqload(::Type{DaqChannels}, h)

    # Is this actually something related to DAQHDF5?
    "__VERSION__" ∉ keys(attributes(h)) &&
        DAQIOTypeError("No __VERSION__ flag found while trying to read DaqConfig")

    # Are we reading the correct version?
    ver = read(attributes(h)["__VERSION__"])
    if ver != 1
        throw(DAQIOVersionError("Error when reading `DaqConfig`. Version 1 expected. Got $ver", "DaqConfig", ver))
    end

    # Check if we are reading an actual DaqConfig
    _type_ = read(attributes(h)["__TYPE__"])
    if _type_ != "DaqChannels"
        throw(DAQIOTypeError("Type error: expected `DaqChannels` got $_type_ "))
    end

    # Everything appears to be ok!
    devname = read(h["devname"])
    devtype = read(h["devtype"])

    chans = read(h["channels"])

    # Let's hope this is enough
    physchans = read(h["physchans"])
    units = read(h["units"])

    return DaqChannels(devname, devtype, chans, units, physchans)
    
end
