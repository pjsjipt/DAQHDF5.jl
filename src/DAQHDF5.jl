module DAQHDF5

using DAQCore
using HDF5

export daqsave, daqload

"""
`daqsave(h, X, name; version=1)`

Save object `X` in a HDF5 file at `h` using name `name`.

Different types of objects implement different `daqsave` methods.

This package implements methods for saving the following type of objects:

 * [`DAQCore.DaqConfig`](@ref)
 * [`DAQCore.DaqChannels`](@ref)
 * [`DAQCore.DaqSamplingRate`](@ref)
 * [`DAQCore.DaqSamplingTimes`](@ref)
 * [`DAQCore.MeasData`](@ref)
 * [`DAQCore.MeasDataSet`](@ref)
 * [`DAQCore.DaqPoints`](@ref)
 * [`DAQCore.DaqCartesianPoints`](@ref)
 * [`DAQCore.DaqPointsProduct`](@ref)
 * [`DAQCore.AbstractOutputDev`](@ref)
 * [`DAQCore.OutputDev`](@ref)
 * [`DAQCore.InputDev`](@ref)
 * [`DAQCore.AbstractInputDev`](@ref)
 * [`DAQCore.ExperimentSetup`](@ref)

Some cases have parametric fields. If Julia knows how to save the types of these
parametric fields, `DAQHDF5` shouldn't have any problems. Several of the types above
have recursive definitions. This should be well handled.

If a package implements some type, to save it, just implement a new method
for `daqsave` and it should work out of the box

There is a keyword argument `version` that is used to specify the version of the file
format. For now only `version == 1` is implemented.

To load an object from a file, use [`daqload`](@ref). As usual reading is more
complicated than writing.
"""
function daqsave end

"""
`daqload(::Type{T}, h)`
`daqload(h)`

Read an object from an HDF5 file. The usual way to do it is simply pass the path to
the object in the HDF5 file. The code will determine the type and dynamically choose
the correct method to use. The types available are the same as those for
[`daqload`](@ref).

When the type is not specified, the type should be provided as an attribute of `h`.
The class hierarchy should be stored under the name `"__DAQCLASS__"`.

## Creating custom readers

If a package wants to implement IO for a new type not implemented by `DAQHDF5`,
it should add a new method `daqload(::Type{T}, h)` where `T` is the type.
Then, the package should register the type using [`adddaqiomethod`](@ref).

"""
function daqload end

const DAQIOTABLE = Dict{String,Any}()

"""
`adddaqiomethod(name, iotype)`

Adds a new IO method for type `iotype` under the name `name` (a `String`).
"""
function adddaqiomethod(name, iotype)
    if name ∈ keys(DAQIOTABLE)
        error("DAQ IO method with name $name is already loaded!")
    end
    DAQIOTABLE[name] = iotype
end

"""
`objectclass(h)`

Returns the class of an object stored in an HDF5 file under `h`.
"""
function objectclass(h)
    # Is this actually something related to DAQHDF5?
    "__DAQVERSION__" ∉ keys(attributes(h)) &&
        DAQIOTypeError("No __DAQVERSION__ flag found while trying to read data")
    
    # Are we reading the correct version?
    ver = read(attributes(h)["__DAQVERSION__"])[begin]
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
include("inputdev.jl")
include("experimentsetup.jl")

end
