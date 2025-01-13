module GmshReader

using Base.Threads
using FlatMat

include("Types.jl")
export Entity
export PhysicalGroup
export Elements

include("GmshFileReader.jl")

export readfile
end
