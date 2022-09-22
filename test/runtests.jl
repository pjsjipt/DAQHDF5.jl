using DAQHDF5
using Test
using DAQCore
using HDF5
using Dates

@testset "DAQHDF5.jl" begin

let
    fname = tempname()
    
    config = DaqConfig(ix=1, iy=2, sx="TEST", sy="STRING",
                       fx=1.1, fy=1.2, ox=rand(10), oy=rand(20))
    chans = DaqChannels("dev", "teste", "P", 64, "Pa", 101:164)
    chansb = DaqChannels("amb", "envconds", ["T", "Ta", "H", "Pa"], ["°C", "°C", "", "kPa"])

    tinit = now()
    rr = DaqSamplingRate(10.0, 10, tinit)
    rt = DaqSamplingTimes(rr)

    
    
    data = MeasData("press", "DTCInitium", rr, rand(64,10), chans)
    datab = MeasData("amb", "envconds", rt, rand(4,10), chansb)
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

        @test chans1.devname == chans.devname
        @test chans1.devtype == chans.devtype
        @test chans1.physchans == chans.physchans
        @test chans1.channels == chans.channels
        @test chans1.chanmap == chans.chanmap
        @test chans1.units == chans.units

        @test rr1.rate == rr.rate
        @test rr1.nsamples == rr.nsamples
        @test rr1.time == rr.time

        @test rt1.t == rt.t

        # MeasData - this is a composite one!
        @test data1.devname == data.devname
        @test data1.devtype == data.devtype
        @test data1.data == data.data
        @test data1.sampling == data.sampling


        @test data1.chans.devname == data.chans.devname
        @test data1.chans.devtype == data.chans.devtype
        @test data1.chans.physchans == data.chans.physchans
        @test data1.chans.channels == data.chans.channels
        @test data1.chans.chanmap == data.chans.chanmap
        @test data1.chans.units == data.chans.units

        @test config2.iparams == config1.iparams
        @test config2.fparams == config1.fparams
        @test config2.sparams == config1.sparams
        @test config2.oparams == config1.oparams

        @test chans1.devname == chans2.devname
        @test chans1.devtype == chans2.devtype
        @test chans1.physchans == chans2.physchans
        @test chans1.channels == chans2.channels
        @test chans1.chanmap == chans2.chanmap
        @test chans1.units == chans2.units

        @test rr2 == rr1
        @test rt2.t == rt1.t
        
        @test data1.devname == data2.devname
        @test data1.devtype == data2.devtype
        @test data1.data == data2.data
        @test data1.sampling == data2.sampling

        @test datab1.chans.devname == datab.chans.devname
        @test datab1.chans.devtype == datab.chans.devtype
        @test datab1.chans.physchans == datab.chans.physchans
        @test datab1.chans.channels == datab.chans.channels
        @test datab1.chans.chanmap == datab.chans.chanmap
        @test datab1.chans.units == datab.chans.units

        @test datab1.chans.devname == datab2.chans.devname
        @test datab1.chans.devtype == datab2.chans.devtype
        @test datab1.chans.physchans == datab2.chans.physchans
        @test datab1.chans.channels == datab2.chans.channels
        @test datab1.chans.chanmap == datab2.chans.chanmap
        @test datab1.chans.units == datab2.chans.units

        @test xdata.devname == xdata1.devname == xdata2.devname
        @test xdata.devtype == xdata1.devtype == xdata2.devtype
        @test xdata.time == xdata1.time == xdata2.time
        @test xdata.devdict == xdata1.devdict == xdata2.devdict


        @test xdata1["press"].devname == data.devname
        @test xdata1["press"].devtype == data.devtype
        @test xdata1["press"].data == data.data
        @test xdata1["press"].sampling == data.sampling

        @test xdata1["press"].chans.devname == data.chans.devname
        @test xdata1["press"].chans.devtype == data.chans.devtype
        @test xdata1["press"].chans.physchans == data.chans.physchans
        @test xdata1["press"].chans.channels == data.chans.channels
        @test xdata1["press"].chans.chanmap == data.chans.chanmap
        @test xdata1["press"].chans.units == data.chans.units
        
        @test xdata1["amb"].devname == datab.devname
        @test xdata1["amb"].devtype == datab.devtype
        @test xdata1["amb"].data == datab.data
        @test xdata1["amb"].sampling.t == datab.sampling.t

        @test xdata1["amb"].chans.devname == datab.chans.devname
        @test xdata1["amb"].chans.devtype == datab.chans.devtype
        @test xdata1["amb"].chans.physchans == datab.chans.physchans
        @test xdata1["amb"].chans.channels == datab.chans.channels
        @test xdata1["amb"].chans.chanmap == datab.chans.chanmap
        @test xdata1["amb"].chans.units == datab.chans.units

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

        @test ideva1.chans.devname == ideva.chans.devname
        @test ideva1.chans.devtype == ideva.chans.devtype
        @test ideva1.chans.physchans == ideva.chans.physchans
        @test ideva1.chans.channels == ideva.chans.channels
        @test ideva1.chans.chanmap == ideva.chans.chanmap
        @test ideva1.chans.units == ideva.chans.units

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

        @test ideva2.chans.devname == ideva.chans.devname
        @test ideva2.chans.devtype == ideva.chans.devtype
        @test ideva2.chans.physchans == ideva.chans.physchans
        @test ideva2.chans.channels == ideva.chans.channels
        @test ideva2.chans.chanmap == ideva.chans.chanmap
        @test ideva2.chans.units == ideva.chans.units
        
        
        
    end
    
        
end
    
end
