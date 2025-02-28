using FlatMat
using GmshReader

physicalGroups, nodes, elements, elementTypes = readfile("test/input/50x50-square.msh")
readfile("test/input/50x50-square.msh")
@time readfile("test/input/1000x1000-square.msh")
readfile("test/input/50x50-square.msh", true)
@time pg, n, e, et = readfile("test/input/1000x1000-square.msh", true)
