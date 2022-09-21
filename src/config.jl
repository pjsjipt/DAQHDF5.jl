# Saving and reading DaqConfig objects

import DataStructures: OrderedDict

DAQIOTABLE["DaqConfig"] = DaqConfig

"""
`daqsave(h, path, c::DaqConfig)`

Save a [`DaqConfig`](@ref) object at `h[path]`.

## Parameters

 * `h` An HDF5 object
 * `path` String specifying where to save the data
 * `c` `DaqConfig` object to be saved.

"""
function daqsave(h, c::DaqConfig, name=""; version=1)

    if name==""
        name = devname(c)
    end

    g = create_group(h, name)

    attributes(g)["__DAQVERSION__"] = 1
    attributes(g)["__DAQCLASS__"] = ["AbstractDaqConfig", "DaqConfig"]

    g["__devname__"] = c.devname
    g["__devtype__"] = c.devtype

    if length(c.iparams) > 0
        gipar = create_group(g, "iparams")
        gipar["parameters"] = collect(keys(c.iparams))
        gipar["values"] = collect(values(c.iparams))
    end
    if length(c.fparams) > 0
        gfpar = create_group(g, "fparams")
        gfpar["parameters"] = collect(keys(c.fparams))
        gfpar["values"] = collect(values(c.fparams))
    end
    if length(c.sparams) > 0
        gspar = create_group(g, "sparams")
        gspar["parameters"] = collect(keys(c.sparams))
        gspar["values"] = collect(values(c.sparams))
    end

    if length(c.oparams) > 0
        # We will do this differently
        # Since individual parameters can have different types,
        # each value will be stored independently and
        # *we assume* that the type can be stored directly!
        # Implement a specific method for other types
        gopar = create_group(g, "oparams")
        attributes(gopar)["__parameters__"] = collect(keys(c.oparams))
        for (k,v) in c.oparams
            gopar[k] = v
        end
    end
    
    return
end



function daqload(::Type{DaqConfig}, h)

    # Is this actually something related to DAQHDF5?
    "__DAQVERSION__" ∉ keys(attributes(h)) &&
        DAQIOTypeError("No __DAQVERSION__ flag found while trying to read in DaqConfig")
        
    # Are we reading the correct version?
    ver = read(attributes(h)["__DAQVERSION__"])
    if ver != 1
        throw(DAQIOVersionError("Error when reading `DaqConfig`. Version 1 expected. Got $ver", "DaqConfig", ver))
    end
    
    # Check if we are reading an actual DaqConfig
    _type_ = read(attributes(h)["__DAQCLASS__"])
    if _type_[end] != "DaqConfig"
        throw(DAQIOTypeError("Type error: expected `DaqConfig` got $_type_ "))
    end

    # If we got to this point, everything should work smoothly...

    devname = read(h["__devname__"])
    devtype = read(h["__devtype__"])

    kw = keys(h)
    
    iparams = OrderedDict{String,Int64}()
    if "iparams" ∈ kw
        parameters = read(h["iparams/parameters"])
        ivalues =  read(h["iparams/values"])
        for i in 1:length(ivalues)
            iparams[parameters[i]] = ivalues[i]
        end
    end


    fparams = OrderedDict{String,Float64}()
    if "fparams" ∈ kw
        parameters = read(h["fparams/parameters"])
        fvalues =  read(h["fparams/values"])
        for i in 1:length(fvalues)
            fparams[parameters[i]] = fvalues[i]
        end
    end

    sparams = OrderedDict{String,String}()
    if "sparams" ∈ kw
        parameters = read(h["sparams/parameters"])
        svalues =  read(h["sparams/values"])
        for i in 1:length(svalues)
            sparams[parameters[i]] = svalues[i]
        end
    end

    oparams = OrderedDict{String,Any}()
    if "oparams" ∈ kw
        g = h["oparams"]
        parameters = read(attributes(g)["__parameters__"])
        
        for p in parameters
            oparams[p] = read(g[p])
        end
            
    end
    
    return DaqConfig(devname, devtype, iparams, fparams, sparams, oparams)
end

    
      
    

