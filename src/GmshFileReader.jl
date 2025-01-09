struct PhysicalGroup
  dim::Int8
  num::Int8
end

function readFile(file::AbstractString)
  f::Vector{String} = open(readlines, file, "r")
  line = 1
  line = readFormat(f, line)
  physicalGroups, line = readPhysicalGroups(f, line)
  entities, line = readEntities(f, line)
  _, line = readPartialEntities(f, line)
  nodes, line = readNodes(f, line, entities)
  elements, line = readElements(f, line, entities)
  return physicalGroups, entities, nodes, elements
end

function readFormat(f, line)
  section = "MeshFormat"
  line = checkSection(section, f, line)
  formatInfo, line = readLine(f, line)
  @assert formatInfo[1] == "4.1" "Wrong version number"
  @assert formatInfo[2] == "0" "Wrong filetype"
  println(("Gmsh file version: " * formatInfo[1]))
  line = checkSection(section, f, line; isEnd=true)
  return line
end

function readPhysicalGroups(f, line)
  section = "PhysicalNames"
  if !checkPossibleSection(section, f, line)
    return (false, line)
  else
    line = checkSection(section, f, line)
  end

  numGroups, line = parseLine(f, line, Int, true)
  groupDict = Dict{String,PhysicalGroup}()
  for _ in 1:numGroups[1]
    groupInfo, line = readLine(f, line)
    dimGroup = parse(Int8, groupInfo[1])
    numGroup = parse(Int8, groupInfo[2])
    groupName = groupInfo[3]
    physGroup = PhysicalGroup(dimGroup, numGroup)
    get!(groupDict, groupName, physGroup)
  end
  line = checkSection(section, f, line; isEnd=true)
  return (groupDict, line)
end

function readEntities(f, line)
  section = "Entities"
  line = checkSection(section, f, line)

  totEntities, line = parseLine(f, line, Int, true)
  totEntities = totEntities[totEntities.>0]
  entities = fill(Vector{Entity}(), size(totEntities, 1))
  for (dim, e) in enumerate(totEntities)
    for _ in 1:e
      entityVector, line = readLine(f, line)
      if dim == 1
        hasPhysTag::Bool = parse(Int, entityVector[5]) != 0
      else
        hasPhysTag = parse(Int, entityVector[8]) != 0
      end
      entity = Entity{dim - 1,hasPhysTag}(entityVector)
      push!(entities[dim], entity)
    end
  end
  line = checkSection(section, f, line; isEnd=true)
  return (entities, line)
end

function readPartialEntities(f, line)
  section = "PartialEntities"
  if !checkPossibleSection(section, f, line)
    return (false, line)
  else
    line = checkSection(section, f, line)
  end
end

function readNodes(f, line, entities)
  # TODO: Store matrix column major order
  section = "Nodes"
  line = checkSection(section, f, line)
  entityBlocks, line = parseLine(f, line, Int, true)
  numEntityBlocks = entityBlocks[1]
  numNodes = entityBlocks[2]
  nodes = Array{Float64,2}(undef, 3, numNodes)
  @views for e in 1:numEntityBlocks
    entityBlock, line = parseLine(f, line, Int, true)
    entDim, entTag = entityBlock[1:2]
    entity = entities[entDim+1, entTag]
    display(entity)
    elemsInBlock = entityBlock[4]
    node_index = parse.(Int, f[line:line+elemsInBlock-1])
    line += elemsInBlock
    nodeVector = split.(f[line:line+elemsInBlock-1], " "; keepempty=false)
    @threads for n in 1:elemsInBlock
      nodes[1:end, node_index[n]] .= parse.(Float64, nodeVector[n])
    end
    line += elemsInBlock
  end
  line = checkSection(section, f, line; isEnd=true)
  return (nodes, line)
end

function readElements(f, line, entities)
  section = "Elements"
  line = checkSection(section, f, line)
  entityBlocks, line = parseLine(f, line, Int, true)
  numEntityBlocks = entityBlocks[1]
  numElements = entityBlocks[2]
  elements = Array{Vector{Int},1}(undef, numElements)
  @views for e in 1:numEntityBlocks
    entity = entities[e]
    entityBlock, line = parseLine(f, line, Int, true)
    # display(entity)
    # display(entityBlock)
    elemsInBlock = entityBlock[4]
    nodeVector = split.(f[line:line+elemsInBlock-1], " "; keepempty=false)
    @threads for n in 1:entityBlock[4]
      element = parse.(Int, nodeVector[n])
      elements[element[1]] = element[2:end]
    end
    line += entityBlock[4]
  end
  line = checkSection(section, f, line; isEnd=true)
  return (elements, line)
end

function parseLine(f, line, type::Type, add_line::Bool)
  return (parse.(type, readLine(f, line; add_line=add_line)[1]), line + 1)
end

function parseLine(f, line, type::Type)
  return parse.(type, readLine(f, line; add_line=false)[1])
end

function readLine(f, line; add_line::Bool=true)
  currentLine = f[line]
  splitLine = split(currentLine, ' '; keepempty=false)
  if add_line
    line += 1
    return (splitLine, line)
  else
    return (splitLine, line)
  end
end

function checkSection(sectionName::String, f, line; isEnd::Bool=false)
  section = f[line]
  line += 1
  if isEnd
    @assert section == "\$End$sectionName" ["Wrong section name, expected $sectionName, got: $section"]
  else
    @assert section == "\$$sectionName" "Wrong section name, expected $sectionName, got: $section"
  end
  return line
end

function checkPossibleSection(sectionName::String, f, line)
  section = f[line]
  if section != "\$$sectionName"
    return false
  else
    line += 1
    return true
  end
end
