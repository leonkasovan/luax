-- Fix rename file with %dd the URL encoded string input to a "plain string"
local working_dir, new_filename, nn

if #arg == 0 then
	print(string.format("This script will rename file \"Name%%20with%%20space\" into \"Name with space\".\nUsage:\n\t#> %s [working_dir]\n", arg[0]))
	working_dir = "."
elseif #arg >= 1 then
	working_dir = arg[1]
end

nn = 0
for file in lfs.dir(working_dir) do
	if file ~= "." and file ~= ".." then
		local attr = lfs.attributes(file)
		if attr.mode == "file" and file:match("%%%d%d") then
			nn = nn + 1
			new_filename = http.unescape(file)
			print(string.format("%d. Rename '%s' to '%s'\n", nn, file, new_filename))
			os.rename(file, new_filename)
		end
	end
end
print(string.format("%d total files renamed.", nn))