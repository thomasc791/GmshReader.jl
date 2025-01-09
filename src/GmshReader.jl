module GmshReader

using Base.Threads
using StaticArrays

include("Types.jl")
export Entity

include("FlatMat.jl")
export FlatMat
export get_elem

include("GmshFileReader.jl")
export PhysicalGroup

export readFile
end
