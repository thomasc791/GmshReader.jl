import Gmsh: gmsh

if gmsh.isInitialized() == false
  gmsh.initialize()
end

dir = ""
if basename(pwd()) == "GmshReader"
  dir = join([pwd(), "/test/"])
else
  dir = join([pwd(), "/"])
end

inputdir = join([dir, "input/"])
files = readdir(inputdir)
for f in files
  if f[end-2:end] == "geo"
    gmsh.option.setNumber("Mesh.SaveAll", 1)
    gmsh.open(join([inputdir, f]))
  end
end

gmsh.finalize()
