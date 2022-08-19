module DAQHDF5

using DAQCore
using HDF5

export daqsave, daqload

function daqsave end
function daqload end

include("errors.jl")

include("config.jl")

end
