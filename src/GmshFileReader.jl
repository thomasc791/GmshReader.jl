function readfile(file::AbstractString)
  f::Vector{String} = readlines(file)
  line = 1
  line = readformat(f, line)
  physicalGroups, pgElements, line = readphysicalgroups(f, line)
  _, line = readentities(f, line)
  _, line = readpartialentities(f, line)
  nodes, line = readnodes(f, line)
  elements, pgElements, line = readelements!(f, line, physicalGroups, pgElements)
  return pgElements, nodes, elements
end

function readformat(f, line)
  section = "MeshFormat"
  line = checksection(section, f, line)
  formatInfo, line = read_line(f, line)
  @assert formatInfo[1] == "4.1" "Wrong version number"
  @assert formatInfo[2] == "0" "Wrong filetype"
  println(("Gmsh file version: " * formatInfo[1]))
  line = checksection(section, f, line; isEnd=true)
  return line
end

function readphysicalgroups(f, line)
  section = "PhysicalNames"
  if !checkpossiblesection(section, f, line)
    return (Dict{PhysicalGroup,String}(), Dict{String,Vector{Int}}(), line)
  else
    line = checksection(section, f, line)
  end

  numGroups, line = parseLine(f, line, Int, true)
  groupDict = Dict{PhysicalGroup,String}()
  physicalGroupElements = Dict{String,Vector{Int}}()
  for _ in 1:numGroups[1]
    groupInfo, line = read_line(f, line)
    groupName = groupInfo[3][2:end-1]
    physGroup = PhysicalGroup(parse.(Int, groupInfo[1:2]))
    get!(groupDict, physGroup, groupName)
    get!(physicalGroupElements, groupName, [])
  end
  line = checksection(section, f, line; isEnd=true)
  return (groupDict, physicalGroupElements, line)
end

function readentities(f, line)
  section = "Entities"
  line = checksection(section, f, line)

  totEntities, line = parseLine(f, line, Int, true)
  totEntities = totEntities[totEntities.>0]
  entities = fill(Vector{Entity}(), size(totEntities, 1))
  for (dim, e) in enumerate(totEntities)
    for _ in 1:e
      entityVector, line = read_line(f, line)
      if dim == 1
        hasPhysTag::Bool = parse(Int, entityVector[5]) != 0
      else
        hasPhysTag = parse(Int, entityVector[8]) != 0
      end
      entity = Entity{dim - 1,hasPhysTag}(entityVector)
      push!(entities[dim], entity)
    end
  end
  line = checksection(section, f, line; isEnd=true)
  return (entities, line)
end

function readpartialentities(f, line)
  section = "PartialEntities"
  if !checkpossiblesection(section, f, line)
    return (false, line)
  else
    line = checksection(section, f, line)
  end
end

function readnodes(f, line)
  # TODO: Store matrix column major order
  section = "Nodes"
  line = checksection(section, f, line)
  entityBlocks, line = parseLine(f, line, Int, true)
  numEntityBlocks = entityBlocks[1]
  numNodes = entityBlocks[2]
  nodes = Array{Float64,2}(undef, 3, numNodes)
  @views for e in 1:numEntityBlocks
    entityBlock, line = parseLine(f, line, Int, true)
    elemsInBlock = entityBlock[4]
    node_index = parse.(Int, f[line:line+elemsInBlock-1])
    line += elemsInBlock
    nodeVector = split.(f[line:line+elemsInBlock-1], " "; keepempty=false)
    @threads for n in 1:elemsInBlock
      nodes[1:end, node_index[n]] .= parse.(Float64, nodeVector[n])
    end
    line += elemsInBlock
  end
  line = checksection(section, f, line; isEnd=true)
  return (nodes, line)
end

function readelements!(f, line, physGroup, pgElements)
  section = "Elements"
  line = checksection(section, f, line)
  entityBlocks, line = parseLine(f, line, Int, true)
  numEntityBlocks = entityBlocks[1]
  numElements = entityBlocks[2]
  elements = Array{Vector{Int},1}(undef, numElements)
  @views for _ in 1:numEntityBlocks
    entityBlock, line = parseLine(f, line, Int, true)
    entDim, entTag = entityBlock[1:2]
    pg = PhysicalGroup(entDim, entTag)
    elemsInBlock = entityBlock[4]
    nodeVector = split.(f[line:line+elemsInBlock-1], " "; keepempty=false)
    elementIndex = parse.(Int, first.(nodeVector))
    @threads for n in 1:elemsInBlock
      # TODO: Add FlatMats to elements instead of regular elements
      # NOTE: Discuss with Paul how to implement the pgs with FMat
      elements[elementIndex[n]] = parse.(Int, nodeVector[n][2:end])
    end
    if haskey(physGroup, pg)
      append!(pgElements[physGroup[pg]], parse.(Int, first.(nodeVector)))
    end
    line += elemsInBlock
  end
  line = checksection(section, f, line; isEnd=true)
  return (elements, pgElements, line)
end

function inputelement!(elementList, element)
  index = element[1]
  elementList[index] = @view element[2:end]
end

function parseLine(f, line, type::Type, add_line::Bool)
  return (parse.(type, read_line(f, line; add_line=add_line)[1]), line + 1)
end

function parseLine(f, line, type::Type)
  return parse.(type, read_line(f, line; add_line=false)[1])
end

function read_line(f, line; add_line::Bool=true)
  currentLine = f[line]
  splitLine = split(currentLine, ' '; keepempty=false)
  if add_line
    line += 1
    return (splitLine, line)
  else
    return (splitLine, line)
  end
end

function checksection(sectionName::String, f, line; isEnd::Bool=false)
  section = f[line]
  line += 1
  if isEnd
    @assert section == "\$End$sectionName" ["Wrong section name, expected $sectionName, got: $section"]
  else
    @assert section == "\$$sectionName" "Wrong section name, expected $sectionName, got: $section"
  end
  return line
end

function checkpossiblesection(sectionName::String, f, line)
  section = f[line]
  if section != "\$$sectionName"
    return false
  else
    line += 1
    return true
  end
end
