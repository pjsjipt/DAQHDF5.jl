DAQIOTABLE["DaqPoints"] = DaqPoints
DAQIOTABLE["AbstractDaqPoints"] = DaqPoints
DAQIOTABLE["DaqCartesianPoints"] = DaqCartesianPoints
DAQIOTABLE["DaqPointsProduct"] = DaqPointsProduct


function daqsave(h, pts::AbstractDaqPoints, name; version=1)

    g = create_group(h, name)

    attributes(g)["__DAQVERSION__"] = 1
    attributes(g)["__DAQCLASS__"] = ["AbstractDaqPoints", "DaqPoints"]

    g["params"] = parameters(pts)
    g["points"] = daqpoints(pts)
    
    return
end

function daqload(::Type{DaqPoints}, h)
    # Is this actually something related to DAQHDF5?
    "__DAQVERSION__" ∉ keys(attributes(h)) &&
        DAQIOTypeError("No __DAQVERSION__ flag found while trying to read DaqConfig")

    # Are we reading the correct version?
    ver = readelem(attributes(h)["__DAQVERSION__"])
    if ver != 1
        throw(DAQIOVersionError("Error when reading `DaqPoints`. Version 1 expected. Got $ver", "DaqPoints", ver))
    end
    
    # Check if we are reading an actual DaqConfig
    _type_ = read(attributes(h)["__DAQCLASS__"])
    if "AbstractDaqPoints" ∉ _type_
        throw(DAQIOTypeError("Type error: expected `DaqPoints` got $_type_ "))
    end

    params = read(h["params"])
    pts = read(h["points"])

    return DaqPoints(params, pts)
end



function daqsave(h, pts::DaqCartesianPoints, name; version=1)

    g = create_group(h, name)

    attributes(g)["__DAQVERSION__"] = 1
    attributes(g)["__DAQCLASS__"] = ["AbstractDaqPoints", "DaqCartesianPoints"]

    g["params"] = parameters(pts)
    g["points"] = daqpoints(pts)
    gax = create_group(g, "axes")

    for (i,ax) in enumerate(pts.axes)
        gax[pts.params[i]] = ax
    end
    
    return
end


function daqload(::Type{DaqCartesianPoints}, h)
    # Is this actually something related to DAQHDF5?
    "__DAQVERSION__" ∉ keys(attributes(h)) &&
        DAQIOTypeError("No __DAQVERSION__ flag found while trying to read DaqConfig")

    # Are we reading the correct version?
    ver = readelem(attributes(h)["__DAQVERSION__"])
    if ver != 1
        throw(DAQIOVersionError("Error when reading `DaqCartesianPoints`. Version 1 expected. Got $ver", "DaqCartesianPoints", ver))
    end
    
    # Check if we are reading an actual DaqConfig
    _type_ = read(attributes(h)["__DAQCLASS__"])
    if _type_[end] != "DaqCartesianPoints"
        throw(DAQIOTypeError("Type error: expected `DaqCartesianPoints` got $_type_ "))
    end

    params = read(h["params"])
    pts = read(h["points"])
    gax = h["axes"]

    axes = Vector{Float64}[]

    for i in eachindex(params)
        ax = read(gax[params[i]])
        push!(axes, ax)
    end
    

    return DaqCartesianPoints(params, axes, pts)
end


function daqsave(h, pts::DaqPointsProduct, name; version=1)

    g = create_group(h, name)

    attributes(g)["__DAQVERSION__"] = 1
    attributes(g)["__DAQCLASS__"] = ["AbstractDaqPoints", "DaqPointsProduct"]

    g["params"] = parameters(pts)
    g["points"] = daqpoints(pts)

    g["numpoints"] = length(pts.points)
    g["ptsidx"] = pts.ptsidx
    
    i = 1
    for p in pts.points
        pname = string(i)
        daqsave(g, p, pname)
        i += i
    end
    
        
    
    return
end


function daqload(::Type{DaqPointsProduct}, h)
    # Is this actually something related to DAQHDF5?
    "__DAQVERSION__" ∉ keys(attributes(h)) &&
        DAQIOTypeError("No __DAQVERSION__ flag found while trying to read DaqConfig")

    # Are we reading the correct version?
    ver = readelem(attributes(h)["__DAQVERSION__"])
    if ver != 1
        throw(DAQIOVersionError("Error when reading `DaqCartesianPoints`. Version 1 expected. Got $ver", "DaqCartesianPoints", ver))
    end
    
    # Check if we are reading an actual DaqConfig
    _type_ = read(attributes(h)["__DAQCLASS__"])
    if _type_[end] != "DaqPointsProduct"
        throw(DAQIOTypeError("Type error: expected `DaqPointsProduct` got $(_type_[end]) "))
    end

    npts = readelem(h["numpoints"])
    ptsidx = read(h["ptsidx"])
    
    pts = AbstractDaqPoints[]

    for i in 1:npts
        g = h[string(i)]
        class = read(attributes(g)["__DAQCLASS__"])
        point = daqload(g)
        push!(pts, point)
    end
    return DaqPointsProduct(pts, ptsidx)
end

