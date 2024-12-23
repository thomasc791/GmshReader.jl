using GmshReader
using Test

@testset "GmshReader.jl" begin
  @test GmshReader.readFile("test/input/singleMesh.msh")
end
