-- Generate DB, search from DB, source from archive.org
-- Source HTM : 
-- https://archive.org/download/nes-roms
-- https://archive.org/download/nes-romset-ultra-us
-- 19:37 22 April 2023, Dhani Novan, Jakarta, Cempaka Putih

dofile('../strict.lua')

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

-- user=aitus95
-- success, function return table
-- fail, function return nil
function archive_user_uploads(user)
	local res = {}
	local done = false
	local page = 1
	local user_url
	
	user_url = 'https://archive.org/details/@'..user..'?tab=uploads&page='
	repeat
		local rc, headers, content = http.request(user_url..tostring(page))
		if rc ~= 0 then
			print("Error: "..http.error(rc), rc)
			return nil
		end
		if content:match('class="no%-results"') then
			done = true
		end
		for link, title in content:gmatch('\n            <a href%="/details/(.-)" title="(.-)"') do
			-- print(link, title)
			res[#res + 1] = link
		end
		print("Page "..page..": "..tostring(#res).."data")
		page = page + 1
		
	until done
	return res
end

-- user_url=https://archive.org/download/nes-roms
-- user_url=https://archive.org/details/nes-roms
-- user_url=nes-roms
function archive_generate_db(user_url, category)
	local fo, output_fname, rc, headers, content, nn
	if user_url == "" or user_url == nil then
		return false
	end
	
	category = category or "general"
	if user_url:match('/details/') then
		user_url = user_url:gsub('/details/','/download/')
		output_fname = user_url:match('download/(.-)$')
	elseif user_url:match('/download/') then
		output_fname = user_url:match('download/(.-)$')
	else
		output_fname = user_url
		user_url = 'https://archive.org/download/'..user_url
	end
	output_fname = output_fname:gsub("%W","_")..".csv"
	
	fo = io.open(output_fname, "w")
	if fo == nil then
		print('Error open a file '..output_fname)
		return false
	end
	rc, headers, content = http.request(user_url)
	if rc ~= 0 then
		print("Error: "..http.error(rc), rc)
		return false
	end
	
	fo:write("#category="..category.."\n")
	fo:write("#url="..user_url.."\n")
	nn = 0
	for w1,w2,w3 in content:gmatch('<td><a href="(.-)">(.-)</a>.-</td>.-<td>.-</td>.-<td>(.-)</td>.-</tr>') do
		if w1:match("%.jpg$") or w1:match("%.torrent$") or w1:match("%.xml$") or w1:match("%.sqlite$") 
		or w1:match("^history/") or w1:match("^/details/") 
		then
			print("Ignore: ", w1)
		else
			w2 = w2:gsub("&amp;", "&")
			w2 = w2:gsub("%.%w+$", "")
			fo:write(w1.."|"..w2.."|"..w3.."\n")
			nn = nn + 1
		end
	end
	fo:close()
	print("Successfully process "..nn.." data")
	return true
end

function archive_find_db(keyword)
	local f
	local nn = 0
	local lower_keyword = keyword:lower()
	
	for file in lfs.dir(".") do
		if file ~= "." and file ~= ".." then
			local attr = lfs.attributes(file)
			if attr.mode == "file" and file:match("%.csv$") then
				for line in io.lines(file) do
					if line:byte(1) ~= 35 then
						f = csv.parse(line, '|')
						if (f[2]:lower()):find(lower_keyword, 1, true) ~= nil then
							print(f[2], f[3], file)
							nn = nn + 1
						end
					end
				end
			end
		end
	end
	print("\n=====================================\nFound "..nn.." data")
	return nn
end

if #arg == 1 then
	archive_generate_db(arg[1])
elseif #arg == 2 then
	if arg[1] == "find" then
		archive_find_db(arg[2])
	end
else
	print(string.format("Generate ROM database from archieve.org.\nUsage: \n\t#> %s [url]", arg[0]))
	print(string.format("\t#> %s \"https://archive.org/download/nes-roms\" ", arg[0]))
	
	-- local list_uploads
	-- list_uploads = archive_user_uploads('aitus95')
	-- for i,v in pairs(list_uploads) do
		-- print(i,"https://archive.org/download/"..v)
	-- end
	-- return true
end
