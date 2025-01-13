struct Entity{T,S}
  dim::UInt8
  tag::Int
  numPhysicalTags::UInt
  physicalTags::Vector{Int}

  function Entity{0,B}(entityVector) where {B}
    typeassert(B, Bool)
    dim = 0
    tag = parse(Int, entityVector[1])
    numPhysTags = parse(UInt8, entityVector[5])
    physicalTags = parse.(Int, entityVector[end-numPhysTags+1:end])
    new{0,B}(dim, tag, numPhysTags, physicalTags)
  end

  function Entity{D,B}(entityVector) where {D,B}
    typeassert(B, Bool)
    dim = D
    tag = parse(Int, entityVector[1])
    numPhysTags = parse(UInt8, entityVector[8])
    physicalTags = parse.(Int, entityVector[9:9+numPhysTags-1])
    new{D,B}(dim, tag, numPhysTags, physicalTags)
  end
end

struct PhysicalGroup
  dim::Int8
  tag::Int8

  function PhysicalGroup(dim::Int, tag::Int)
    new(dim, tag)
  end
  function PhysicalGroup(vals::Array{Int,1})
    new(vals[1], vals[2])
  end
end

struct Elements
  D0::FMat
  D1::FMat
  D2::FMat
  D3::FMat

  function Elements(vertices, edges, surfaces, volumes)
    new(FMat(vertices), FMat(edges), FMat(surfaces), FMat(volumes))
  end
end
