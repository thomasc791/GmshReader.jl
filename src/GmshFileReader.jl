struct Elements
  # TODO: 
  zero::Matrix{Int}
  startOne::Int
  one::Matrix{Int}
  startTwo::Int
  two::Matrix{Int}
  startThree::Int
  three::Matrix{Int}
end

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
  readPartialEntities(f, line)
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
    return false
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
  if !checkPossibleSection(section, f, line)
    return false
  else
    line = checkSection(section, f, line)
  end

  numEntities, line = parseLine(f, line, Int, true)
  entities = Vector{Any}()
  for (dim, e) in enumerate(numEntities[numEntities.>0])
    for _ in 1:e
      entityVector, line = readLine(f, line)
      if dim == 1
        hasPhysTag::Bool = parse(Int, entityVector[5]) != 0
      else
        hasPhysTag = parse(Int, entityVector[8]) != 0
      end
      entity = Entity{dim - 1,hasPhysTag}(entityVector)
      push!(entities, entity)
    end
  end
  line = checkSection(section, f, line; isEnd=true)
  return (entities, line)
end

function readPartialEntities(f, line)
  section = "PartialEntities"
  if !checkPossibleSection(section, f, line)
    return false
  else
    line = checkSection(section, f, line)
  end
end

function readNodes(f, line, entities)
  section = "Nodes"
  line = checkSection(section, f, line)
  entityBlocks, line = parseLine(f, line, Int, true)
  numEntityBlocks = entityBlocks[1]
  numNodes = entityBlocks[2]
  nodes = Array{Float64,2}(undef, numNodes, 3)
  @views for e in 1:numEntityBlocks
    _ = entities[e]
    entityBlock, line = parseLine(f, line, Int, true)
    elemsInBlock = entityBlock[4]
    node_index = parse.(Int, f[line:line+elemsInBlock-1])
    line += elemsInBlock
    nodeVector = split.(f[line:line+elemsInBlock-1], " "; keepempty=false)
    @threads for n in 1:elemsInBlock
      nodes[node_index[n], 1:end] .= parse.(Float64, nodeVector[n])
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
  elements = fill(Vector{Int}(), numElements)
  @views for _ in 1:numEntityBlocks
    entityBlock, line = parseLine(f, line, Int, true)
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
  !add_line && return (splitLine, line)
  line += 1
  return (splitLine, line)
end

function checkSection(sectionName::String, f, line; isEnd::Bool=false)
  section = f[line]
  line += 1
  isEnd && @assert section == "\$End$sectionName" ["Wrong section name, expected $sectionName, got: $section"]
  isEnd && return line
  @assert section == "\$$sectionName" "Wrong section name, expected $sectionName, got: $section"
  return line
end

function checkPossibleSection(sectionName::String, f, line)
  section = f[line]
  section != "\$$sectionName" && return false
  line += 1
  return true
end
