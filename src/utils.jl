"""
    parseLine(f, line, type::Type)
    parseLine(f, line, type::Type, add_line::Bool)

Parse the `line` in the file `f` and parse all elements to `type`. If `add_line` is given the line number is incremented.
"""
function parseLine(f, line, type::Type)
  return parse.(type, read_line(f, line; add_line=false)[1])
end

function parseLine(f, line, type::Type, add_line::Bool)
  return (parse.(type, read_line(f, line; add_line=add_line)[1]), line + 1)
end

"""
    read_line(f::Vector{String}, line; add_line::Bool=true)

Read the line: `line` of `f`.
"""
function read_line(f::Vector{String}, line; add_line::Bool=true)
  currentLine = f[line]
  splitLine = split(currentLine, ' '; keepempty=false)
  if add_line
    line += 1
    return (splitLine, line)
  else
    return (splitLine, line)
  end
end

"""
    checksection(sectionName::String, f, line; isEnd::Bool=false)

Check if the section with `sectionName` that is currently read is actually the correct one. Results in an error if this is not the case.
"""
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

"""
    checkpossiblesection(sectionName::String, f, line)

Check if the section with `sectionName` that is currently read is actually the correct one. Does not result in an error if this is not the case.
"""
function checkpossiblesection(sectionName::String, f, line)
  section = f[line]
  if section != "\$$sectionName"
    return false
  else
    line += 1
    return true
  end
end

"""
    elements_from_pg(elements::Vector{GFMat{Int}}, physicalGroups::Dict{String,PGElements}, group::String)

Get all elements that belong to a physical group with string `group`.
"""
function elements_from_pg(elements::Vector{GFMat{Int}}, physicalGroups::Dict{String,PGElements}, group::String)
  pg = physicalGroups[group]
  groupElements = Vector{Vector{Int}}()
  for (i, d) in enumerate(pg.dim)
    currentGroup = pg.indices[i]
    append!(groupElements, elements[d+1][currentGroup])
  end
  return GFMat(groupElements)
end

function _parse_vector(elements::Vector{T}, type::Type) where {T}
  e = Vector{type}(undef, length(elements) - 1)
  for i in 1:length(elements)-1
    e[i] = parse(Int, elements[i+1])
  end
  return e
end

"""
    getelements(elementTypes::Vector{Dict{T1,T2}}, dim::Int) where {T1,T2}

Get all the elements that belong to a certain dimension `dim`.
"""
function getelements(elementTypes::Vector{Dict{T1,T2}}, dim::Int) where {T1,T2}
  return elementTypes[dim+1]
end
