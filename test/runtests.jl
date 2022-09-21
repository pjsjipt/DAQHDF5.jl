using DAQHDF5
using Test
using DAQCore
using HDF5
using Dates

@testset "DAQHDF5.jl" begin

let
    fname = tempname()
    
    config = DaqConfig("test", "nothing", ix=1, iy=2, sx="TEST", sy="STRING",
                       fx=1.1, fy=1.2, ox=rand(10), oy=rand(20))
    chans = DaqChannels("dev", "teste", "P", 64, "Pa", 101:164)

    tinit = now()

    rr = DaqSamplingRate(10.0, 10, tinit)

    rt = DaqSamplingTimes(rr)


    data = MeasData("press", "DTCInitium", rr, rand(64,10), chans)
    
    
    h5open(fname, "w") do h
        daqsave(h, config, "config")
        daqsave(h, chans, "channels")
        daqsave(h, rr, "samplingrate")
        daqsave(h, rt, "samplingtimes")
        daqsave(h, data, "measdata")
    end
    
    h5open(fname, "r") do h
        config1 = daqload(DaqConfig, h["config"])
        chans1 = daqload(DaqChannels, h["channels"])
        rr1 = daqload(DaqSamplingRate, h["samplingrate"])
        rt1 = daqload(DaqSamplingTimes, h["samplingtimes"])
        data1 = daqload(MeasData, h["measdata"])
        
        config2 = daqload(h["config"])
        chans2 = daqload(h["channels"])
        rr2 = daqload(h["samplingrate"])
        rt2 = daqload(h["samplingtimes"])
        data2 = daqload(h["measdata"])
        
        @test config1.devname == config.devname
        @test config1.devtype == config.devtype
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

        @test config2.devname == config1.devname
        @test config2.devtype == config1.devtype
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
        
    end
    
        
end
    
end
