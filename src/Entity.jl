struct Entity{T,S}
  dim::UInt8
  tag::Int
  numBoundingTags::UInt8
  numPhysicalTags::UInt
  physicalTags::Vector{Int}
  minPos::Vector{Float64}
  maxPos::Vector{Float64}
  boundTags::Vector{Int}

  function Entity{0,true}(entityVector)
    dim = 0
    tag = parse(Int, entityVector[1])
    minPos = parse.(Float64, entityVector[2:4])
    maxPos = parse.(Float64, entityVector[2:4])
    numPhysTags = parse(UInt8, entityVector[5])
    physicalTags = parse.(Int, entityVector[end-numPhysTags+1:end])
    new{dim,true}(dim, tag, 0, numPhysTags, physicalTags, minPos, maxPos, [0])
  end

  function Entity{0,false}(entityVector)
    dim = 0
    tag = parse(Int, entityVector[1])
    minPos = parse.(Float64, entityVector[2:4])
    maxPos = parse.(Float64, entityVector[2:4])
    numPhysTags = parse(UInt8, entityVector[5])
    physicalTags = parse.(Int, entityVector[end-numPhysTags+1:end])
    new{dim,false}(dim, tag, 0, numPhysTags, physicalTags, minPos, maxPos, [0])
  end

  function Entity{T,true}(entityVector) where {T}
    dim = T
    tag = parse(Int, entityVector[1])
    minPos = parse.(Float64, entityVector[2:4])
    maxPos = parse.(Float64, entityVector[5:7])
    numPhysTags = parse(UInt8, entityVector[8])
    physicalTags = parse.(Int, entityVector[9:9+numPhysTags-1])
    numBoundTags = parse(UInt8, entityVector[9+numPhysTags])
    boundTags = parse.(Int, entityVector[end-numBoundTags+1:end])
    new{T,true}(dim, tag, numBoundTags, numPhysTags, physicalTags, minPos, maxPos, boundTags)
  end

  function Entity{T,false}(entityVector) where {T}
    dim = T
    tag = parse(Int, entityVector[1])
    minPos = parse.(Float64, entityVector[2:4])
    maxPos = parse.(Float64, entityVector[5:7])
    numBoundTags = parse(UInt8, entityVector[9])
    boundTags = parse.(Int, entityVector[end-numBoundTags+1:end])
    new{T,false}(dim, tag, numBoundTags, 0, [0], minPos, maxPos, boundTags)
  end
end
