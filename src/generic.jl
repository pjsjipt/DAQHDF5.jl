# Storing generic stuff
# Often we need to store more complex stuff.
# Julia provides the Serialization module and we use it
# to store unknown stuff.
# We are not responsible for changes in the format
# The user is responsible for including the appropriate packages as needed
# when loading data that have types defined in 3rd party packages.

using Serialization

function daqsave(h, x, name; version=1)
    g =  create_group(h, name)
    attributes(g)["__DAQVERSION__"] = 1
    attributes(g)["__DAQCLASS__"] = ["Serialization"]
    buffer = IOBuffer()
    serialize(buffer, x)
    data = take!(buffer)
    g["data"] = data
end

function daqload_generic(h)
    # Is this actually something related to DAQHDF5?
    "__DAQVERSION__" ∉ keys(attributes(h)) &&
        DAQIOTypeError("No __DAQVERSION__ flag found while trying to read ExperimentSetup")
    ver = readelem(attributes(h)["__DAQVERSION__"])
    if ver != 1
        throw(DAQIOVersionError("Error when reading generic serialized data. Version 1 expected. Got $ver", "ExperimentSetup", ver))
    end
    
    _type_ = read(attributes(h)["__DAQCLASS__"])
    if _type_[end] != "Serialization"
        throw(DAQIOTypeError("Type error: expected `Serialization` got $_type_ "))
    end
    
    return deserialize(IOBuffer(read(h["data"])))
end

