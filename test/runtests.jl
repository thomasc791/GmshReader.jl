using GmshReader
using Test

@testset "FlatMat" begin
  pg1x1, ent1x1, n1x1, e1x1 = readFile("input/1x1-square.msh")
  mesh50x50 = readFile("input/50x50-square.msh")

  fm1x1 = FlatMat(e1x1)
  function array_is_same()
    is_same::Bool = true
    for (i, val) in enumerate(e1x1)
      is_same = is_same && fm1x1[i+1] != val
    end
    return is_same
  end

  @test array_is_same()
end
