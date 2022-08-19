

abstract type DAQIOError <: Exception end
struct DAQIOLoadError <: DAQIOError
    msg::String
    field::String
end

struct DAQIOTypeError <: DAQIOError
    msg::String
end

struct DAQIOVersionError <: DAQIOError
    msg::String
    objttype::String
    version::Int
end
