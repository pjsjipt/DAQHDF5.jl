module DAQHDF5

using DAQCore
using HDF5

export daqsave, daqload

function daqsave end
function daqload end

const DAQIOTABLE = Dict{String,Any}()

function adddaqiomethod(name, iotype)
    if name ∈ keys(DAQIOTABLE)
        error("DAQ IO method with name $name is already loaded!")
    end
    DAQIOTABLE[name] = iotype
end

function objectclass(h)
    # Is this actually something related to DAQHDF5?
    "__DAQVERSION__" ∉ keys(attributes(h)) &&
        DAQIOTypeError("No __DAQVERSION__ flag found while trying to read data")
    
    # Are we reading the correct version?
    ver = read(attributes(h)["__DAQVERSION__"])
    if ver != 1
        throw(DAQIOVersionError("Error when reading object. Version 1 expected. Got $ver", "", ver))
    end

    # Check if we are reading an actual DaqConfig
    _type_ = read(attributes(h)["__DAQCLASS__"])
    return _type_[end]
    
end

function daqload(h)
    # Get the class of object stored
    name = objectclass(h)
    if name ∉ keys(DAQIOTABLE)
        error("I don't know how to load objects of type $name. Perhaps you need to load the appropriate package?")
    end

    return daqload(DAQIOTABLE[name], h)
end

include("errors.jl")
include("config.jl")
include("channels.jl")
include("sampling.jl")
include("measdata.jl")
include("points.jl")
include("outputdev.jl")
end
