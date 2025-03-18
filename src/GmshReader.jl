module GmshReader

using Base.Threads

include("Types.jl")
export Entity
export PhysicalGroup
export PGElements

include("utils.jl")
export elements_from_pg
export getelements

include("GmshFileReader.jl")

export readfile
end
