struct PhysicalGroup
  dim::Int8
  num::Int8
end

function readFile(file::AbstractString)
  f = open(readlines, file, "r")
  line = [1]
  readFormat(f, line)
  readPhysicalGroups(f, line)
  entities = readEntities(f, line)
  readPartialEntities(f, line)
  nodes = readNodes(f, line, entities)
  elements = readElements(f, line, entities)
  return entities, nodes, elements
end

function readFormat(f, line)
  section = "MeshFormat"
  checkSection(section, f, line)
  version, fileType, _ = readLine(f, line)
  @assert fileType == "0" "Wrong filetype"
  println(("Gmsh file version: " * version))
  checkSection(section, f, line; isEnd=true)
  return
end

function readPhysicalGroups(f, line)
  section = "PhysicalNames"
  checkSection(section, f, line)

  numGroups = readLine(f, line)
  groupDict = Dict{String,PhysicalGroup}()
  for _ in 1:parse(Int, numGroups)
    dim, num, groupName = readLine(f, line)
    dimGroup = parse(Int, dim)
    numGroup = parse(Int, num)
    physGroup = PhysicalGroup(dimGroup, numGroup)
    get!(groupDict, groupName, physGroup)
  end
  checkSection(section, f, line; isEnd=true)
  return
end

function readEntities(f, line)
  section = "Entities"
  checkSection(section, f, line)
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
      display(dim - 1)
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
  checkSection(section, f, line)
  numEntityBlocks, numNodes, minNodeTag, maxNodeTag = parseLine(f, line, Int)
  nodes = fill([], numNodes)
  display((numEntityBlocks, numNodes, minNodeTag, maxNodeTag))
  n = 0
  for e in 1:numEntityBlocks
    entity = entities[e]
    entityDim, entityTag, parametric, numNodesInBlock = parseLine(f, line, Int)
    nodesInBlock = zeros(Int, numNodesInBlock)
    for n in 1:numNodesInBlock
      nodesInBlock[n] = parse(Int, readLine(f, line))
    end
    for n in 1:numNodesInBlock
      nodes[nodesInBlock[n]] = parseLine(f, line, Float64)
    end
  end
  checkSection(section, f, line; isEnd=true)
  return nodes
end

function readElements(f, line, entities)
  section = "Elements"
  checkSection(section, f, line)
  numEntityBlocks, numElements, minElementTag, maxElementTag = parseLine(f, line, Int)
  elements = fill([], numElements)
  display((numEntityBlocks, numElements, minElementTag, maxElementTag))
  n = 0
  for e in 1:numEntityBlocks
    entity = entities[e]
    entityDim, entityTag, parametric, numElementsInBlock = parseLine(f, line, Int)
    for _ in 1:numElementsInBlock
      element = parseLine(f, line, Int)
      display(element)
      elements[element[1]] = element[2:end]
    end
  end
  checkSection(section, f, line; isEnd=true)
  return elements
end

function parseLine(f, line, type::Type)
  content = readLine(f, line)
  content = content[content.!=""]
  return parse.(type, content)
end

function readLine(f, line)
  currentLine = f[line][1]
  line[1] += 1
  splitLine = split(currentLine, " ")
  splitLine.size[1] == 1 && return currentLine
  content = split(currentLine, " ")
  content = content[content.!=""]
  return content
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
