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

  dir = ""
  if basename(pwd()) == "GmshReader"
    dir = join([pwd(), "/test/"])
  else
    dir = join([pwd(), "/"])
  end

  include(join([dir, "meshgen.jl"]))
  pg1, n1, e1 = readfile("input/1x1-square.msh")
  pg50, n50, e50 = readfile("input/50x50-square.msh")

  @testset "FlatMat integration" begin

    # testing correct typing
    @test isa(e1, Vector{GFMat{Int}})
    @test isa(e50, Vector{GFMat{Int}})
  end

  @testset "PhysicalGroups" begin
    left_elements = elements_from_pg(e1, pg1, "left")
    right_elements = elements_from_pg(e1, pg1, "right")

    function correct_pos(elements, nodes, pos)
      correct = true
      for e in elements
        for n in e
          correct &= nodes[1, n] == pos
        end
      end
      return correct
    end

    @test correct_pos(left_elements, n1, 0)
    @test correct_pos(right_elements, n1, 1)
  end
end
