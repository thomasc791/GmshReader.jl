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
gmsh.option.setNumber("Mesh.SaveAll", 1)
for f in files
  f_name = f[1:end-4]
  f_ext = f[end-2:end]

  if f_ext == "geo" && !isfile(join([inputdir, f_name, ".msh"]))
    gmsh.open(join([inputdir, f]))
  end
end

gmsh.finalize()
