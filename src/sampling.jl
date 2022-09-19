# Read sampling information

using Dates

function daqsave(h, s::DaqSamplingRate, name=""; version=1)


    if name==""
        name = "sampling"
    end

    g = create_group(h, name)

    attributes(g)["__DAQVERSION__"] = 1
    attributes(g)["__DAQCLASS__"] = ["AbstractDaqSampling", "DaqSamplingRate"]

    g["rate"] = s.rate
    g["nsamples"] = s.nsamples
    g["time"] = s.time.instant.periods.value

    return
    
end

function daqload(::Type{DaqSamplingRate}, h)

    # Is this actually something related to DAQHDF5?
    "__DAQVERSION__" ∉ keys(attributes(h)) &&
        DAQIOTypeError("No __DAQVERSION__ flag found while trying to read in DaqConfig")
        
    # Are we reading the correct version?
    ver = read(attributes(h)["__DAQVERSION__"])[begin]
    if ver != 1
        throw(DAQIOVersionError("Error when reading `DaqSamplingRate`. Version 1 expected. Got $ver", "DaqSamplingRate", ver))
    end
    
    # Check if we are reading an actual DaqConfig
    _type_ = read(attributes(h)["__DAQCLASS__"])
    if _type_[end] != "DaqSamplingRate"
        throw(DAQIOTypeError("Type error: expected `DaqSamplingRate` got $_type_ "))
    end

    rate = read(h["rate"])[begin]
    nsamples = read(h["nsamples"])[begin]
    ms = read(h["time"])[begin]

    t = DateTime(Dates.UTInstant{Millisecond}(Millisecond(ms)))
    
    return DaqSamplingRate(rate, nsamples, t)
end



function daqsave(h, s::DaqSamplingTimes{DateTime}, name=""; version=1)


    if name==""
        name = "sampling"
    end

    g = create_group(h, name)

    attributes(g)["__DAQVERSION__"] = 1
    attributes(g)["__DAQCLASS__"] = ["AbstractDaqSampling","DaqSamplingTimes"]

    
    g["time"] = [tt.instant.periods.value for tt in s.t]
    
    return
    
end

function daqload(::Type{DaqSamplingTimes}, h)

    # Is this actually something related to DAQHDF5?
    "__DAQVERSION__" ∉ keys(attributes(h)) &&
        DAQIOTypeError("No __DAQVERSION__ flag found while trying to read in DaqSamplingTimes")
        
    # Are we reading the correct version
    ver = read(attributes(h)["__DAQVERSION__"])
    if ver[begin] != 1
        throw(DAQIOVersionError("Error when reading `DaqSamplingTimes`. Version 1 expected. Got $ver", "DaqSamplingTimes", ver))
    end
    
    # Check if we are reading an actual DaqConfig
    _type_ = read(attributes(h)["__DAQCLASS__"])
    if _type_[begin] != "DaqSamplingTimes"
        throw(DAQIOTypeError("Type error: expected `DaqSamplingTimes` got $_type_ "))
    end

    t = read(h["time"])

    # We are going to assume that it is a DateTime
    t1 = [DateTime(Dates.UTInstant{Millisecond}(Millisecond(ms))) for ms in t]

    return DaqSamplingTimes(t1)
    
end


function daqload(::Type{AbstractDaqSampling}, h)

    # Is this actually something related to DAQHDF5?
    "__DAQVERSION__" ∉ keys(attributes(h)) &&
        DAQIOTypeError("No __DAQVERSION__ flag found while trying to read in sampling rates")
        
    # Are we reading the correct version
    ver = read(attributes(h)["__DAQVERSION__"])[begin]
    if ver != 1
        throw(DAQIOVersionError("Error when reading sampling rate. Version 1 expected. Got $ver", "DaqConfig", ver))
    end
    
    # Check if we are reading an actual sampling rate info
    _class_ = read(attributes(h)["__DAQCLASS__"])
    if _class_[begin] != "AbstractDaqSampling"
        throw(DAQIOTypeError("Type error: expected `AbstractDaqSampling` got $_type_ "))
    end

    _type_ = _class_[end]

    if _type_ == "DaqSamplingRate"
        return daqload(DaqSamplingRate, h)
    elseif _type_ == "DaqSamplingTimes"
        return daqload(DaqSamplingTimes, h)
    end

end

        
    
