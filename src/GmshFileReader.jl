struct Elements
  # TODO 
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
  f = open(readlines, file, "r")
  line = [1]
  readFormat(f, line)
  @time physicalGroups = readPhysicalGroups(f, line)
  @time entities = readEntities(f, line)
  @time readPartialEntities(f, line)
  @time nodes = readNodes(f, line, entities)
  @time elements = readElements(f, line, entities)
  return physicalGroups, entities, nodes, elements
end

function readFormat(f, line)
  section = "MeshFormat"
  checkPossibleSection(section, f, line)
  version, fileType, _ = readLine(f, line)
  @assert version == "4.1" "Wrong version number"
  @assert fileType == "0" "Wrong filetype"
  println(("Gmsh file version: " * version))
  checkSection(section, f, line; isEnd=true)
  return
end

function readPhysicalGroups(f, line)
  section = "PhysicalNames"
  if !checkPossibleSection(section, f, line)
    return false
  end

  numGroups = readLine(f, line)
  groupDict = Dict{String,PhysicalGroup}()
  for _ in 1:parse(Int, numGroups)
    dim, num, groupName = readLine(f, line)
    dimGroup = parse(Int, dim)
    numGroup = parse(Int, num)
    groupName = groupName[2:end-1]
    physGroup = PhysicalGroup(dimGroup, numGroup)
    get!(groupDict, groupName, physGroup)
  end
  checkSection(section, f, line; isEnd=true)
  return groupDict
end

function readEntities(f, line)
  section = "Entities"
  if !checkPossibleSection(section, f, line)
    return false
  end

  numEntities = parseLine(f, line, Int)
  entities = Vector{Any}()
  for (dim, e) in enumerate(numEntities[numEntities.>0])
    for _ in 1:e
      entityVector = readLine(f, line)
      if dim == 1
        hasPhysTag::Bool = parse(Int, entityVector[5]) != 0
      else
        hasPhysTag = parse(Int, entityVector[8]) != 0
      end
      entity = Entity{dim - 1,hasPhysTag}(entityVector)
      push!(entities, entity)
    end
  end
  checkSection(section, f, line; isEnd=true)
  return entities
end

function readPartialEntities(f, line)
  section = "PartialEntities"
  if !checkPossibleSection(section, f, line)
    return false
  end
end

function readNodes(f, line, entities)
  section = "Nodes"
  checkPossibleSection(section, f, line)
  numEntityBlocks, numNodes, minNodeTag, maxNodeTag = parseLine(f, line, Int)
  nodes = Array{Float64,2}(undef, numNodes, 3)
  n = 0
  for e in 1:numEntityBlocks
    entity = entities[e]
    entityDim, entityTag, parametric, numNodesInBlock = parseLine(f, line, Int)
    nodesInBlock = zeros(Int, numNodesInBlock)
    for n in 1:numNodesInBlock
      nodesInBlock[n] = parse(Int, readLine(f, line))
    end
    for n in 1:numNodesInBlock
      nodes[nodesInBlock[n], 1:end] = parseLine(f, line, Float64)
    end
  end
  checkSection(section, f, line; isEnd=true)
  return nodes
end

function readElements(f, line, entities)
  section = "Elements"
  checkPossibleSection(section, f, line)
  numEntityBlocks, numElements, _, _ = parseLine(f, line, Int)
  elements = fill(Vector{Int}(), numElements)
  for _ in 1:numEntityBlocks
    _, _, _, numElementsInBlock = parseLine(f, line, Int)
    for _ in 1:numElementsInBlock
      element = parseLine(f, line, Int)
      elements[element[1]] = element[2:end]
    end
  end
  checkSection(section, f, line; isEnd=true)
  return elements
end

function parseLine(f, line, type::Type)
  return parse.(type, readLine(f, line))
end

function readLine(f, line)
  currentLine = f[line][1]
  line[1] += 1
  splitLine = split(currentLine, " "; keepempty=false)
  splitLine.size[1] == 1 && return currentLine
  return splitLine
end

function checkSection(sectionName::String, f, line; isEnd::Bool=false)
  section = readLine(f, line)
  isEnd && @assert section == "\$End$sectionName" ["Wrong section name, expected $sectionName, got: $section"]
  isEnd && return
  @assert section == "\$$sectionName" "Wrong section name, expected $sectionName, got: $section"
  return
end

function checkPossibleSection(sectionName::String, f, line)
  section = readLine(f, line)
  if section != "\$$sectionName"
    line[1] -= 1
    return false
  end
  return true
end
