import DataStructures: OrderedDict

DAQIOTABLE["ExperimentSetup"] = ExperimentSetup


function daqsave(h, dev::ExperimentSetup, name; version=1)
    g = create_group(h, name)

    attributes(g)["__DAQVERSION__"] = 1
    attributes(g)["__DAQCLASS__"] = ["AbstractExperimentSetup", "ExperimentSetup"]

    g["lastpoint"] = dev.lastpoint
    g["idx"] = dev.idx
    g["axes"] = collect(keys(dev.axmap))
    g["parameters"] = collect(values(dev.axmap))

    daqsave(g, dev.idev, "input_devices")
    daqsave(g, dev.points,"points")
    daqsave(g, dev.odev, "output_devices")

end

function daqload(::Type{ExperimentSetup}, h)
    # Is this actually something related to DAQHDF5?
    "__DAQVERSION__" ∉ keys(attributes(h)) &&
        DAQIOTypeError("No __DAQVERSION__ flag found while trying to read ExperimentSetup")

    # Are we reading the correct version?
    ver = read(attributes(h)["__DAQVERSION__"])
    if ver != 1
        throw(DAQIOVersionError("Error when reading `ExperimentSetup`. Version 1 expected. Got $ver", "ExperimentSetup", ver))
    end

    _type_ = read(attributes(h)["__DAQCLASS__"])
    if _type_[end] != "ExperimentSetup"
        throw(DAQIOTypeError("Type error: expected `ExperimentSetup` got $_type_ "))
    end

    lastpoint = read(h["lastpoint"])
    idx = read(h["idx"])
    params = read(h["parameters"])
    axes = read(h["axes"])
    axmap = OrderedDict{String,String}()
    parmap = OrderedDict{String,String}()
    for (a,p) in zip(axes, params)
        axmap[a] = p
        parmap[p] = a
    end

    idev = daqload(h["input_devices"])
    points = daqload(h["points"])
    odev = daqload(h["output_devices"])
    
    return ExperimentSetup(lastpoint, false, idev, points, odev, axmap, parmap, idx)
    
end

