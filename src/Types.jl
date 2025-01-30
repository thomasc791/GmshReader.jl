struct Entity{T,S}
  dim::UInt64
  tag::Int
  numPhysicalTags::UInt
  physicalTags::Vector{Int}

  Entity{T,S}(dim, tag, numPhysicalTags, physicalTags) where {T,S} = new{T,S}(dim, tag, numPhysicalTags, physicalTags)
end

function Entity{0,B}(entityVector) where {B}
  typeassert(B, Bool)
  dim = 0
  tag = parse(Int, entityVector[1])
  numPhysTags = parse(UInt8, entityVector[5])
  physicalTags = parse.(Int, entityVector[end-numPhysTags+1:end])
  Entity{0,B}(dim, tag, numPhysTags, physicalTags)
end

function Entity{D,B}(entityVector) where {D,B}
  typeassert(B, Bool)
  dim = D
  tag = parse(Int, entityVector[1])
  numPhysTags = parse(UInt8, entityVector[8])
  physicalTags = parse.(Int, entityVector[9:9+numPhysTags-1])
  Entity{D,B}(dim, tag, numPhysTags, physicalTags)
end

struct PhysicalGroup
  dim::Int64
  tag::Int64

  PhysicalGroup(dim::Int64, tag::Int64) = new(dim, tag)
  PhysicalGroup(vals::Vector{Int64}) = new(vals[1], vals[2])
end

struct PhysicalGroupEntity
  dim::Int64
  tag::Int64
end

"""
...
"""
struct PGElements
  dim::Vector{Int}
  etypes::Vector{Int}
  indices::Vector{Vector{Int}}

  PGElements(dim::Vector{Int}, etypes::Vector{Int}, indices::Vector{Vector{Int}}) = new(dim, etypes, indices)
end
