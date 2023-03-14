using DAQHDF5
using Test
using DAQCore
using HDF5
using Dates
import DataStructures: OrderedDict

@testset "DAQHDF5.jl" begin

let
    fname = tempname()
    
    config = DaqConfig(ix=1, iy=2, sx="TEST", sy="STRING",
                       fx=1.1, fy=1.2, ox=rand(10), oy=rand(20))
    chans = DaqChannels("P", 64, 101:164)
    chansb = DaqChannels(["T", "Ta", "H", "Pa"])

    tinit = now()
    rr = DaqSamplingRate(10.0, 10, tinit)
    rt = DaqSamplingTimes(rr)

    
    
    data = MeasData("press", "DTCInitium", rr, rand(64,10), chans, "Pa")
    datab = MeasData("amb", "envconds", rt, rand(4,10), chansb, ["°C", "°C", "", "kPa"])
    xdata = MeasDataSet("measurements", "measdataset", tinit, (data, datab))
    
    ptsa = DaqPoints(x=1:10, y=0.1:0.1:1.0)
    ptsb = DaqCartesianPoints(w=1:3, z=0.1:0.1:1.0)
    ptsc = DaqPointsProduct((ptsa, ptsb))

    odeva = OutputDev("robot", "ROBOT", ["x", "y", "z"], DaqConfig())
    odevb = OutputDev("ang", "turntable", ["theta"], DaqConfig())
    odevc = OutputDevSet("setup", (odeva, odevb))

    ideva = InputDev("input_a", "daqboard1", chans, config)
    idevb = InputDev("input_b", "daqboard2", nothing, nothing)
    idevc = DeviceSet("a+b", (ideva, idevb), 1)
    
    
    h5open(fname, "w") do h
        daqsave(h, config, "config")
        daqsave(h, chans, "channels")
        daqsave(h, rr, "samplingrate")
        daqsave(h, rt, "samplingtimes")
        daqsave(h, data, "measdata")
        daqsave(h, datab, "measdata2")
        daqsave(h, xdata, "measurements")
        daqsave(h, ptsa, "pointsa")
        daqsave(h, ptsb, "pointsb")
        daqsave(h, ptsc, "pointsc")
        daqsave(h, odeva, "robot")
        daqsave(h, odevb, "ang")
        daqsave(h, odevc, "setup")
        daqsave(h, ideva, "input_a")
        daqsave(h, idevb, "input_b")
        daqsave(h, idevc, "input_a+b")
        
    end
    
    h5open(fname, "r") do h
    
        config1 = daqload(DaqConfig, h["config"])
        chans1 = daqload(DaqChannels, h["channels"])
        rr1 = daqload(DaqSamplingRate, h["samplingrate"])
        rt1 = daqload(DaqSamplingTimes, h["samplingtimes"])
        data1 = daqload(MeasData, h["measdata"])
        datab1 = daqload(MeasData, h["measdata2"])
        xdata1 = daqload(MeasDataSet, h["measurements"])
        ptsa1 = daqload(DaqPoints, h["pointsa"])
        ptsb1 = daqload(DaqCartesianPoints, h["pointsb"])
        ptsc1 = daqload(DaqPointsProduct, h["pointsc"])

        odeva1 = daqload(h["robot"])
        odevc1 = daqload(h["setup"])

    
        config2 = daqload(h["config"])
        chans2 = daqload(h["channels"])
        rr2 = daqload(h["samplingrate"])
        rt2 = daqload(h["samplingtimes"])
        data2 = daqload(h["measdata"])
        datab2 = daqload(MeasData, h["measdata2"])
        xdata2 = daqload(h["measurements"])

        ideva1 = daqload(h["input_a"])
        idevb1 = daqload(h["input_b"])
        idevc1 = daqload(h["input_a+b"])

        @test config1.iparams == config.iparams
        @test config1.sparams == config.sparams
        @test config1.fparams == config.fparams
        @test config1.oparams == config.oparams

        @test chans1.physchans == chans.physchans
        @test chans1.channels == chans.channels
        @test chans1.chanmap == chans.chanmap

        @test rr1.rate == rr.rate
        @test rr1.nsamples == rr.nsamples
        @test rr1.time == rr.time

        @test rt1.t == rt.t

        # MeasData - this is a composite one!
        @test data1.devname == data.devname
        @test data1.devtype == data.devtype
        @test data1.data == data.data
        @test data1.sampling == data.sampling
        @test data1.units == data.units

        @test data1.chans.physchans == data.chans.physchans
        @test data1.chans.channels == data.chans.channels
        @test data1.chans.chanmap == data.chans.chanmap
        
        @test config2.iparams == config1.iparams
        @test config2.fparams == config1.fparams
        @test config2.sparams == config1.sparams
        @test config2.oparams == config1.oparams

        @test chans1.physchans == chans2.physchans
        @test chans1.channels == chans2.channels
        @test chans1.chanmap == chans2.chanmap

        @test rr2 == rr1
        @test rt2.t == rt1.t
        
        @test datab1.devname == datab.devname
        @test datab1.devtype == datab.devtype
        @test datab1.data == datab.data
        @test datab1.sampling.t == datab.sampling.t
        @test datab1.units == datab.units
        
        @test datab1.chans.physchans == datab.chans.physchans
        @test datab1.chans.channels == datab.chans.channels
        @test datab1.chans.chanmap == datab.chans.chanmap

        @test datab1.chans.physchans == datab2.chans.physchans
        @test datab1.chans.channels == datab2.chans.channels
        @test datab1.chans.chanmap == datab2.chans.chanmap

        @test xdata.devname == xdata1.devname == xdata2.devname
        @test xdata.devtype == xdata1.devtype == xdata2.devtype
        @test xdata.time == xdata1.time == xdata2.time
        @test xdata.devdict == xdata1.devdict == xdata2.devdict


        @test xdata1["press"].devname == data.devname
        @test xdata1["press"].devtype == data.devtype
        @test xdata1["press"].data == data.data
        @test xdata1["press"].sampling == data.sampling

        @test xdata1["press"].chans.physchans == data.chans.physchans
        @test xdata1["press"].chans.channels == data.chans.channels
        @test xdata1["press"].chans.chanmap == data.chans.chanmap
        
        @test xdata1["amb"].devname == datab.devname
        @test xdata1["amb"].devtype == datab.devtype
        @test xdata1["amb"].data == datab.data
        @test xdata1["amb"].sampling.t == datab.sampling.t

        @test xdata1["amb"].chans.physchans == datab.chans.physchans
        @test xdata1["amb"].chans.channels == datab.chans.channels
        @test xdata1["amb"].chans.chanmap == datab.chans.chanmap

        @test parameters(ptsa) == parameters(ptsa1)
        @test parameters(ptsb) == parameters(ptsb1)
        @test parameters(ptsc) == parameters(ptsc1)

        @test daqpoints(ptsa) == daqpoints(ptsa1)
        @test daqpoints(ptsb) == daqpoints(ptsb1)
        @test daqpoints(ptsc) == daqpoints(ptsc1)

        for i in 1:length(ptsb.axes)
            @test ptsb.axes[i] == ptsb1.axes[i]
        end
        @test ptsc.ptsidx == ptsc1.ptsidx

        @test parameters(ptsc.points[1]) == parameters(ptsa)
        @test parameters(ptsc.points[2]) == parameters(ptsb)
        @test daqpoints(ptsc.points[1]) == daqpoints(ptsa)
        @test daqpoints(ptsc.points[2]) == daqpoints(ptsb)

        @test axesnames(odeva1) == axesnames(odeva)
        @test devname(odeva1) == devname(odeva)

        @test devname(odevc1) == devname(odevc)
        @test axesnames(odevc1) == axesnames(odevc)
        @test axesnames(odevc1["robot"]) == axesnames(odeva)
        @test axesnames(odevc1["ang"]) == axesnames(odevb)

        @test devname(ideva1) == devname(ideva)
        @test devname(idevb1) == devname(idevb)
        @test devtype(ideva1) == devtype(ideva)
        @test devtype(idevb1) == devtype(idevb)

        @test isnothing(idevb1.chans)
        @test isnothing(idevb1.config)

        @test ideva1.config.iparams == ideva.config.iparams
        @test ideva1.config.sparams == ideva.config.sparams
        @test ideva1.config.fparams == ideva.config.fparams
        @test ideva1.config.oparams == ideva.config.oparams

        @test ideva1.chans.physchans == ideva.chans.physchans
        @test ideva1.chans.channels == ideva.chans.channels
        @test ideva1.chans.chanmap == ideva.chans.chanmap

        ideva2 = idevc1["input_a"]
        idevb2 = idevc1["input_b"]
        
        @test devname(ideva2) == devname(ideva)
        @test devname(idevb2) == devname(idevb)
        @test devtype(ideva2) == devtype(ideva)
        @test devtype(idevb2) == devtype(idevb)

        @test isnothing(idevb2.chans)
        @test isnothing(idevb2.config)

        @test ideva2.config.iparams == ideva.config.iparams
        @test ideva2.config.sparams == ideva.config.sparams
        @test ideva2.config.fparams == ideva.config.fparams
        @test ideva2.config.oparams == ideva.config.oparams

        @test ideva2.chans.physchans == ideva.chans.physchans
        @test ideva2.chans.channels == ideva.chans.channels
        @test ideva2.chans.chanmap == ideva.chans.chanmap
        
    end
end
    
    # Let's test the generic interface using serialization
    let
        fname = tempname()
        chans = 64

        tinit = now()
        rr = DaqSamplingRate(10.0, 10, tinit)

        press = MeasData("press", "DTCInitium", rr, rand(64,10), chans, "Pa")

        x = (rand(5), Dict("a"=>1, "b"=>2, "c"=>3), rand(2,3,4), 1//2)
        
        h5open(fname, "w") do h
            daqsave(h, x, "generic_data"; version=1)
            daqsave(h, press, "pressure"; version=1)
        end

        y,p = h5open(fname, "r") do h
            y = daqload(h["generic_data"])
            p = daqload(h["pressure"])
            y,p
        end

        @test x[1] == y[1]
        @test x[2] == y[2]
        @test x[3] == y[3]
        @test x[4] == y[4]
        
        @test isa(p, MeasData)
        @test devname(p) == devname(press)
        @test devtype(p) == devtype(press)
        @test p.sampling == press.sampling
        @test p.data == press.data
        @test p.chans == chans
        @test p.units == press.units
    end        

    # Lets test Array stuff
    
    let
        xInt64 = rand(Int64, 4,3)
        xUInt64 = rand(UInt64, 4,3)
        xInt32 = rand(Int32, 4,3)
        xUInt32 = rand(UInt32, 4,3)
        xInt16 = rand(Int16, 4,3)
        xUInt16 = rand(UInt16, 4,3)
        xInt8 = rand(Int8, 4,3)
        xUInt8 = rand(UInt8, 4,3)
        xF32 = rand(Float32, 4,3)
        xF64 = rand(Float64, 4,3)
        xC32 = rand(ComplexF32, 4,3)
        xC64 = rand(ComplexF64, 4,3)
        xString = ["Julia áéíóú", "is àèìòù", "an αβγ", "awesome ∑∏×", "language ℵ"]

        
        fname = tempname()
        h5open(fname, "w") do h
            daqsave(h, xInt64, "Int64")
            daqsave(h, xUInt64, "UInt64")
            daqsave(h, xInt32, "Int32")
            daqsave(h, xUInt32, "UInt32")
            daqsave(h, xInt16, "Int16")
            daqsave(h, xUInt16, "UInt16")
            daqsave(h, xInt8, "Int8")
            daqsave(h, xUInt8, "UInt8")
            daqsave(h, xF32, "F32")
            daqsave(h, xF64, "F64")
            daqsave(h, xC32, "C32")
            daqsave(h, xC64, "C64")
            daqsave(h, xString, "String")
            
        end
        
        h5open(fname, "r") do h
            yInt64 = daqload(h["Int64"])
            @test size(yInt64) == size(xInt64)
            @test eltype(yInt64) == eltype(xInt64)
            @test yInt64 == xInt64

            yUInt64 = daqload(h["UInt64"])
            @test size(yUInt64) == size(xUInt64)
            @test eltype(yUInt64) == eltype(xUInt64)
            @test yUInt64 == xUInt64

            yInt32 = daqload(h["Int32"])
            @test size(yInt32) == size(xInt32)
            @test eltype(yInt32) == eltype(xInt32)
            @test yInt32 == xInt32

            yUInt32 = daqload(h["UInt32"])
            @test size(yUInt32) == size(xUInt32)
            @test eltype(yUInt32) == eltype(xUInt32)
            @test yUInt32 == xUInt32

            yInt16 = daqload(h["Int16"])
            @test size(yInt16) == size(xInt16)
            @test eltype(yInt16) == eltype(xInt16)
            @test yInt16 == xInt16

            yUInt16 = daqload(h["UInt16"])
            @test size(yUInt16) == size(xUInt16)
            @test eltype(yUInt16) == eltype(xUInt16)
            @test yUInt16 == xUInt16

            yInt8 = daqload(h["Int8"])
            @test size(yInt8) == size(xInt8)
            @test eltype(yInt8) == eltype(xInt8)
            @test yInt8 == xInt8

            yUInt8 = daqload(h["UInt8"])
            @test size(yUInt8) == size(xUInt8)
            @test eltype(yUInt8) == eltype(xUInt8)
            @test yUInt8 == xUInt8
            

            yF32 = daqload(h["F32"])
            @test size(yF32) == size(xF32)
            @test eltype(yF32) == eltype(xF32)
            @test yF32 == xF32

            yF64 = daqload(h["F64"])
            @test size(yF64) == size(xF64)
            @test eltype(yF64) == eltype(xF64)
            @test yF64 == xF64

            yC32 = daqload(h["C32"])
            @test size(yC32) == size(xC32)
            @test eltype(yC32) == eltype(xC32)
            @test yC32 == xC32

            yC64 = daqload(h["C64"])
            @test size(yC64) == size(xC64)
            @test eltype(yC64) == eltype(xC64)
            @test yC64 == xC64

            yString = daqload(h["String"])
            @test size(yString) == size(xString)
            @test eltype(yString) == eltype(xString)
            @test yString == xString
            
        end
        
        
    end

    let
        xInt64 = rand(Int64)
        xUInt8 = rand(UInt8)
        xF32 = rand(Float32)
        xF64 = rand(Float64)
        xC32 = rand(ComplexF32)
        xC64 = rand(ComplexF64)
        xString = "aeiou áéíóú ãẽĩõũ äëïöü αβγδ ∑∏ ×⊗⨣"

        fname = tempname()
        h5open(fname, "w") do h
            daqsave(h, xInt64, "Int64")
            daqsave(h, xUInt8, "UInt8")
            daqsave(h, xF32, "F32")
            daqsave(h, xF64, "F64")
            daqsave(h, xC32, "C32")
            daqsave(h, xC64, "C64")
            daqsave(h, xString, "String")
            
        end
        
        h5open(fname, "r") do h
            yInt64 = daqload(h["Int64"])
            yUInt8 = daqload(h["UInt8"])
            yF32 = daqload(h["F32"])
            yF64 = daqload(h["F64"])
            yC32 = daqload(h["C32"])
            yC64 = daqload(h["C64"])
            yString = daqload(h["String"])

            @test typeof(yInt64) == typeof(xInt64)
            @test yInt64 == xInt64
            
            @test typeof(yUInt8) == typeof(xUInt8)
            @test yUInt8 == xUInt8

            @test typeof(yF32) == typeof(xF32)
            @test yF32 == xF32

            @test typeof(yF64) == typeof(xF64)
            @test yF64 == xF64

            @test typeof(yC32) == typeof(xC32)
            @test yC32 == xC32

            @test typeof(yC64) == typeof(xC64)
            @test yC64 == xC64

            @test typeof(yString) == typeof(xString)
            @test yString == xString
            
            
        end
    end
    

    # Let's  test DaqPlan

    let
        fname = tempname()
        # Let's create a daq device
        # Now the experimental points
        pts_a = DaqCartesianPoints(x=[-100,0,100], z=[100,200,300,400])
        pts_b = DaqPoints(ang=0:15.0:345.0)
        pts = DaqPointsProduct(pts_a, pts_b)

        # Actuators
        odev_a = TestOutputDev("turntable", ["ang"])
        odev_b = TestOutputDev("robot", ["x", "z"])
        odev = OutputDevSet("wind_tunnel", (odev_a, odev_b))

        s = DaqPlan(odev,  pts)

        h5open(fname, "w") do h
            daqsave(h, s, "setup")
        end

        h5open(fname, "r") do h
            s1 = daqload(h["setup"])
            # Now we will check if we get the same thing
            @test daqpoints(s1) == daqpoints(s)
            @test numaxes(s1) == numaxes(s)
            @test axesnames(s1) == axesnames(s)
            @test parameters(s1) == parameters(s)
            @test devname(s1) == devname(s)
            @test s1.axes ==  s.axes
            @test s1.avals == s.avals
        end
        

    end
    
             
            
end
