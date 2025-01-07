module GmshReader

using CSV
using DataFrames
using Base.Threads

include("Entity.jl")
export Entity

include("GmshFileReader.jl")
export PhysicalGroup

export readFormat
export readEntities
export readPartialEntities
export readNodes
export readElements
export checkPossibleSection
export parseLine
export readLine

include("CSVtest.jl")

export readFile
export readFileCSV
end
