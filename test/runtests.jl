using GmshReader
using FlatMat
using Test
using Aqua
using JET

@testset "GmshReader.jl" begin
  # @testset "Code quality (Aqua.jl)" begin
  #   Aqua.test_all(FlatMat)
  # end
  # @testset "Code linting (JET.jl)" begin
  #   JET.test_package(FlatMat; target_defined_modules=true)
  # end

  @testset "FlatMat integration" begin
    dir = ""
    if basename(pwd()) == "GmshReader"
      dir = join([pwd(), "/test/"])
    else
      dir = join([pwd(), "/"])
    end

    include(join([dir, "meshgen.jl"]))
    pg1x1, n1x1, e1x1 = readfile("input/1x1-square.msh")
    mesh50x50 = readfile("input/50x50-square.msh")

    fm1x1 = FMat(e1x1)
    function array_is_same()
      is_same::Bool = true
      for (i, val) in enumerate(e1x1)
        is_same = is_same && fm1x1[i] == val
      end
      return is_same
    end

    @test array_is_same()
    @test fm1x1[1:end] == FMat(e1x1[1:end])
    @test fm1x1[2:5] == FMat(e1x1[2:5])
    @test fm1x1[end:end] == FMat(e1x1[end:end])
  end
end
