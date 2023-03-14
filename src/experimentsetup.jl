
DAQIOTABLE["ExperimentSetup"] = ExperimentSetup


function daqsave(h, dev::ExperimentSetup, name; version=1)
    g = create_group(h, name)

    attributes(g)["__DAQVERSION__"] = 1
    attributes(g)["__DAQCLASS__"] = ["AbstractExperimentSetup", "ExperimentSetup"]

    
    daqsave(g, dev.idev, "input_devices")
    daqsave(g, dev.plan, "plan")
    daqsave(g, dev.filt, "filter")

end

function daqload(::Type{ExperimentSetup}, h)
    # Is this actually something related to DAQHDF5?
    "__DAQVERSION__" ∉ keys(attributes(h)) &&
        DAQIOTypeError("No __DAQVERSION__ flag found while trying to read ExperimentSetup")

    # Are we reading the correct version?
    ver = readelem(attributes(h)["__DAQVERSION__"])
    if ver != 1
        throw(DAQIOVersionError("Error when reading `ExperimentSetup`. Version 1 expected. Got $ver", "ExperimentSetup", ver))
    end

    _type_ = read(attributes(h)["__DAQCLASS__"])
    if _type_[end] != "ExperimentSetup"
        throw(DAQIOTypeError("Type error: expected `ExperimentSetup` got $_type_ "))
    end

    idev = daqload(h["input_devices"])
    plan = daqload(h["plan"])
    if "filt" ∈ keys(h)
        filt = daqload(h["filt"])
    else
        filt = nothing
    end

    return ExperimentSetup(idev, plan, filt)
end

