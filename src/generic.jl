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
        DAQIOTypeError("No __DAQVERSION__ flag found while trying to read generic julia data")
    ver = readelem(attributes(h)["__DAQVERSION__"])
    if ver != 1
        throw(DAQIOVersionError("Error when reading generic serialized data. Version 1 expected. Got $ver", "Generic", ver))
    end
    
    _type_ = read(attributes(h)["__DAQCLASS__"])
    if _type_[end] != "Serialization"
        throw(DAQIOTypeError("Type error: expected `Serialization` got $_type_ "))
    end
    
    return deserialize(IOBuffer(read(h["data"])))
end


DAQIOTABLE["Array"] = Array

function daqsave(h, x::Array, name; version=1)
    g = create_group(h, name)
    attributes(g)["__DAQVERSION__"] = 1
    attributes(g)["__DAQCLASS__"] = ["Array"]
    g["data"] = x
end

function daqload(::Type{Array}, h)
    # Is this actually something related to DAQHDF5?
    "__DAQVERSION__" ∉ keys(attributes(h)) &&
        DAQIOTypeError("No __DAQVERSION__ flag found while trying to read Array")

    # Are we reading the correct version?
    ver = readelem(attributes(h)["__DAQVERSION__"])
    if ver != 1
        throw(DAQIOVersionError("Error when reading `Array`. Version 1 expected. Got $ver", "Array", ver))
    end

    # Check if we are reading an actual DaqConfig
    _type_ = read(attributes(h)["__DAQCLASS__"])
    if _type_[end] != "Array"
        throw(DAQIOTypeError("Type error: expected `Array` got $_type_ "))
    end
    data = read(h["data"])

    return data
end

    
DAQIOTABLE["Number"] = Number

function daqsave(h, x::Number, name; version=1)
    g = create_group(h, name)
    attributes(g)["__DAQVERSION__"] = 1
    attributes(g)["__DAQCLASS__"] = ["Number"]
    g["data"] = x
end

function daqload(::Type{Number}, h)
    # Is this actually something related to DAQHDF5?
    "__DAQVERSION__" ∉ keys(attributes(h)) &&
        DAQIOTypeError("No __DAQVERSION__ flag found while trying to read Number")

    # Are we reading the correct version?
    ver = readelem(attributes(h)["__DAQVERSION__"])
    if ver != 1
        throw(DAQIOVersionError("Error when reading `Number`. Version 1 expected. Got $ver", "Number", ver))
    end

    # Check if we are reading an actual DaqConfig
    _type_ = read(attributes(h)["__DAQCLASS__"])
    if _type_[end] != "Number"
        throw(DAQIOTypeError("Type error: expected `Number` got $_type_ "))
    end
    data = read(h["data"])[1]

    return data
    
end

DAQIOTABLE["String"] = AbstractString

function daqsave(h, x::AbstractString, name; version=1)
    g = create_group(h, name)
    attributes(g)["__DAQVERSION__"] = 1
    attributes(g)["__DAQCLASS__"] = ["String"]
    g["data"] = x
end

function daqload(::Type{AbstractString}, h)
    # Is this actually something related to DAQHDF5?
    "__DAQVERSION__" ∉ keys(attributes(h)) &&
        DAQIOTypeError("No __DAQVERSION__ flag found while trying to read String")

    # Are we reading the correct version?
    ver = readelem(attributes(h)["__DAQVERSION__"])
    if ver != 1
        throw(DAQIOVersionError("Error when reading `String`. Version 1 expected. Got $ver", "String", ver))
    end

    # Check if we are reading an actual DaqConfig
    _type_ = read(attributes(h)["__DAQCLASS__"])
    if _type_[end] != "String"
        throw(DAQIOTypeError("Type error: expected `String` got $_type_ "))
    end
    data = read(h["data"])

    return data
    
end




