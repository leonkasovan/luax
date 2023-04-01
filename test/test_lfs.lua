-- Example 1
function attrdir (path)
  for file in lfs.dir(path) do
	  if file ~= "." and file ~= ".." then
		  local f = path..'/'..file
		  print ("\t "..f)
		  local attr = lfs.attributes (f)
		  assert (type(attr) == "table")
		  if attr.mode == "directory" then
			  attrdir (f)
		  else
			  for name, value in pairs(attr) do
				  print (name, value)
			  end
		  end
	  end
  end
end
attrdir (".")

-- Example 2
for file in lfs.dir(".") do
	if file ~= "." and file ~= ".." then
		local attr = lfs.attributes(file)
		if attr.mode == "file" then
			print("file: "..file)
		elseif attr.mode == "directory" then
			print("directory: "..file)
		end
	end
end