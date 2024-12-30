using GmshReader
using Test

@testset "GmshReader.jl" begin
  mesh = GmshReader.readFile("input/1x1-square.msh")
end
