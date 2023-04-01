-- Source HTM : 
-- https://archive.org/download/nes-roms
-- https://archive.org/download/nes-romset-ultra-us

function load_file(filename)
	local fi, content

	fi = io.open(filename, "r")
	if fi == nil then
		print("[error] Load file "..filename)
		return nil
	end
	content = fi:read("*a")
	fi:close()
	return content
end

if #arg == 1 then
	os.execute('del romset.htm')
	rc, headers = http.request{url = arg[1], output_filename = 'romset.htm'}
	if rc ~= 0 then
		print("Error: "..http.error(rc), rc)
		return false
	end
	content = load_file('romset.htm')
	for w1,w2,w3 in content:gmatch('<td><a href="(.-)">(.-)</a>.-</td>.-<td>.-</td>.-<td>(.-)</td>.-</tr>') do
		w2 = w2:gsub("&amp;", "&")
		w2 = w2:gsub("%.%w+$", "")
		print(w1.."|"..w2.."|"..w3)
	end
else
	print(string.format("Generate ROM database from archieve.org.\nUsage: \n\t#> %s [url]", arg[0]))
	print(string.format("\t#> %s \"https://archive.org/download/nes-roms\" ", arg[0]))
	return true
end
