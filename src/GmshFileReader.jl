"""
    readfile(file::AbstractString)

Read and parse the `gmsh` .msh file. Returns a dictionary, the nodes, and the elements. The dictionary has the physical groups and corrresponding elements. The nodes consists of the 3xN matrix with xyz coordinates. The elements is a `Vector{GFMat{Int}}` with all elements in the mesh.

# Note
This function only works for Gmsh file version 4.1. The user also either has to run gmsh with `-save_all` or use the `Mesh.SaveAll` option.
"""
function readfile(file::AbstractString)
  f::Vector{String} = readlines(file)
  line = 1
  line = readformat(f, line)
  physicalGroups, pgElements, line = read_physical_groups(f, line)
  physicalEntities, line = readentities(f, line, physicalGroups)
  _, line = read_partial_entities(f, line)
  nodes, line = readnodes(f, line)
  @time elements, pgElements, elementTypes, line = readelements!(f, line, physicalEntities, pgElements)
  return pgElements, nodes, elements, elementTypes
end

"""
readformat(f::Vector{String}, line)

Read and check the format of a file. Gives an error is the file format is not 4.1, otherwise it will return the current line number.
"""
function readformat(f::Vector{String}, line)
  section = "MeshFormat"
  line = checksection(section, f, line)
  formatInfo, line = read_line(f, line)
  @assert formatInfo[1] == "4.1" "Wrong version number"
  @assert formatInfo[2] == "0" "Wrong filetype"
  line = checksection(section, f, line; isEnd=true)
  return line
end

"""
    readphysicalgroups(f::Vector{String}, line)

Read the physical groups, and return two dictionaries. The first dictionary contains the PhysicalGroup corresponding with the physical group name. The second dictionary is an empty dictionary containing the names corresponding to the to the empty vector that is used by `readelements`.
"""
function read_physical_groups(f::Vector{String}, line)
  section = "PhysicalNames"
  if !checkpossiblesection(section, f, line)
    return (Dict{PhysicalGroup,String}(), Dict{String,Vector{Vector{Int}}}(), line)
  else
    line = checksection(section, f, line)
  end

  numGroups, line = parseLine(f, line, Int, true)
  groupDict = Dict{PhysicalGroup,String}()
  pgElements = Dict{String,Vector{Vector{Int}}}()
  for _ in 1:numGroups[1]
    groupInfo, line = read_line(f, line)
    groupName = groupInfo[3][2:end-1]
    physGroup = PhysicalGroup(parse.(Int, groupInfo[1:2]))
    get!(groupDict, physGroup, groupName)
    get!(pgElements, groupName, [[]])
  end
  line = checksection(section, f, line; isEnd=true)
  return (groupDict, pgElements, line)
end

"""
    readentities(f::Vector{String}, line, physicalGroups)

Read the entities, and return a dictionary. The dictionary contains the PhysicalGroupEntity corresponding wiht the physical group name. This is necessary, since the tag of the physical group is different from the entity tag which is read by `readelements`.
"""
function readentities(f::Vector{String}, line, physicalGroups)
  section = "Entities"
  line = checksection(section, f, line)

  totEntities, line = parseLine(f, line, Int, true)
  totEntities = totEntities[totEntities.>0]
  physicalEntities = Dict{PhysicalGroupEntity,String}()
  dim = 0
  for e in totEntities
    for _ in 1:e
      entityVector, line = read_line(f, line)
      if dim == 0
        hasPhysTag::Bool = parse(Int, entityVector[5]) != 0
      else
        hasPhysTag = parse(Int, entityVector[8]) != 0
      end
      entity = Entity{dim,hasPhysTag}(entityVector)

      for tag in entity.physicalTags
        pg = PhysicalGroup(dim, tag)
        if haskey(physicalGroups, pg)
          get!(physicalEntities, PhysicalGroupEntity(dim, entity.tag), physicalGroups[pg])
        end
      end
    end
    dim += 1
  end
  line = checksection(section, f, line; isEnd=true)
  return (physicalEntities, line)
end

"""
    readpartialentities(f::Vector{String}, line)
"""
function read_partial_entities(f::Vector{String}, line)
  section = "PartialEntities"
  if !checkpossiblesection(section, f, line)
    return (false, line)
  else
    line = checksection(section, f, line)
  end
end

"""
    readnodes(f::Vector{String}, line)

Read the nodes, and return the matrix of the read nodes. Julia is column-major, so the matrix is 3xN rather than Nx3.
"""
function readnodes(f::Vector{String}, line)
  section = "Nodes"
  line = checksection(section, f, line)
  entityBlocks, line = parseLine(f, line, Int, true)
  numEntityBlocks = entityBlocks[1]
  numNodes = entityBlocks[2]
  nodes = Matrix{Float64}(undef, 3, numNodes)
  @views for e in 1:numEntityBlocks
    entityBlock, line = parseLine(f, line, Int, true)
    elemsInBlock = entityBlock[4]
    nodeIndex = parse.(Int, f[line:line+elemsInBlock-1])
    line += elemsInBlock
    nodeVector = split.(f[line:line+elemsInBlock-1], " "; keepempty=false)
    for n in 1:elemsInBlock
      nodes[:, nodeIndex[n]] .= parse.(Float64, nodeVector[n])
    end
    line += elemsInBlock
  end
  line = checksection(section, f, line; isEnd=true)
  return (nodes, line)
end

"""
    readelements!(f::Vector{String}, line, physicalEntities, pgElements)

Read the elements, and return the elements and a Dict containing the physical group name corresponding to the element indices. The elements are returned as a vector of `FMat`. It loops over the all the entities and checks if it belongs to a physical group. If it does, it adds the element indices to the physical group. The elements are separated per dimension so it is necessary to store the dimensionality of the elements as well.
"""
function readelements!(f::Vector{String}, line, physicalEntities, pgElements)
  section = "Elements"
  line = checksection(section, f, line)
  entityBlocks, line = parseLine(f, line, Int, true)
  numEntityBlocks = entityBlocks[1]
  localElements = Vector{Vector{Int}}()
  elements = Vector{GFMat{Int}}()
  elementTypes = Vector{Dict{Int,Vector{UnitRange}}}()
  localElementTypes = Dict{Int,Vector{UnitRange}}()
  size, dim, index = 0, 0, 0
  @views for _ in 1:numEntityBlocks
    entityBlock, line = parseLine(f, line, Int, true)
    entDim, entTag, eType = entityBlock[1:3]
    if dim != entDim
      dim, size, index = entDim, 0, 0
      push!(elements, GFMat(localElements))
      push!(elementTypes, localElementTypes)
      localElements = Vector{Vector{Int}}()
      localElementTypes = Dict{Int,Vector{UnitRange}}()
    end
    pe = PhysicalGroupEntity(entDim, entTag)
    elemsInBlock = entityBlock[4]
    if !haskey(localElementTypes, eType)
      get!(localElementTypes, eType, [range(index + 1, index + elemsInBlock)])
    else
      push!(localElementTypes[eType], range(index + 1, index + elemsInBlock))
    end
    nodeVector = split.(f[line:line+elemsInBlock-1], " "; keepempty=false)
    resize!(localElements, size += elemsInBlock)
    for n in 1:elemsInBlock
      localElements[index+n] = _parse_vector(nodeVector[n], Int)
    end
    if haskey(physicalEntities, pe)
      push!(pgElements[physicalEntities[pe]][1], entDim)
      push!(pgElements[physicalEntities[pe]], (1:elemsInBlock) .+ index)
    end
    index += elemsInBlock
    line += elemsInBlock
  end
  push!(elementTypes, localElementTypes)
  push!(elements, GFMat(localElements))
  pgs = _create_physical_groups!(pgElements)
  line = checksection(section, f, line; isEnd=true)
  return (elements, pgs, elementTypes, line)
end

"""
    _create_physical_groups!(pgElements::Dict{String,Vector{Vector{Int}}})

Convert the vector of vectors with the dimensions and element indices to a dictionary with the group name and the corresponding `PGElements`.
"""
function _create_physical_groups!(pgElements::Dict{String,Vector{Vector{Int}}})
  pgs = Dict{String,PGElements}()
  for (key, val) in pgElements
    get!(pgs, key, PGElements(val[1], val[2:end]))
  end
  return pgs
end
