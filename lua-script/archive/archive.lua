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

function archive_user_uploads(user)
	local res = {}
	local done = false
	local page = 1, user_url
	
	user_url = 'https://archive.org/details/@'..user..'?tab=uploads&page='
	repeat
		print("Page ", page)
		local rc, headers, content = http.request(user_url..tostring(page))
		if rc ~= 0 then
			print("Error: "..http.error(rc), rc)
			return nil
		end
		if content:match('class="no%-results"') then
			done = true
		end
		for link, title in content:gmatch('\n            <a href%="/details/(.-)" title="(.-)"') do
			print(link, title)
			res[#res + 1] = link
		end
		page = page + 1
	until done
	return res
end

if #arg == 1 then
	os.execute('del romset.htm')
	rc, headers = http.request{url = arg[1], output_filename = 'romset.htm'}
	if rc ~= 0 then
		print("Error: "..http.error(rc), rc)
		return false
	end
	print("#url="..url)
	content = load_file('romset.htm')
	for w1,w2,w3 in content:gmatch('<td><a href="(.-)">(.-)</a>.-</td>.-<td>.-</td>.-<td>(.-)</td>.-</tr>') do
		if w1:match("%.jpg$") or w1:match("%.torrent$") or w1:match("%.xml$") or w1:match("%.sqlite$") 
		or w1:match("^history/") or w1:match("^/details/") 
		then
			--print("Ignore: ", w1)
		else
			w2 = w2:gsub("&amp;", "&")
			w2 = w2:gsub("%.%w+$", "")
			print(w1.."|"..w2.."|"..w3)
		end
	end
else
	local list_uploads
	print(string.format("Generate ROM database from archieve.org.\nUsage: \n\t#> %s [url]", arg[0]))
	print(string.format("\t#> %s \"https://archive.org/download/nes-roms\" ", arg[0]))
	
	-- rc, headers = http.request{url = 'https://archive.org/details/@aitus95?tab=uploads', output_filename = 'list_user_uploads1.htm'}
	-- if rc ~= 0 then
		-- print("Error: "..http.error(rc), rc)
		-- return false
	-- end
	-- rc, headers = http.request{url = 'https://archive.org/details/@aitus95?tab=uploads&page=2', output_filename = 'list_user_uploads2.htm'}
	-- if rc ~= 0 then
		-- print("Error: "..http.error(rc), rc)
		-- return false
	-- end
	-- rc, headers = http.request{url = 'https://archive.org/details/@aitus95?tab=uploads&page=5', output_filename = 'list_user_uploads5.htm'}
	-- if rc ~= 0 then
		-- print("Error: "..http.error(rc), rc)
		-- return false
	-- end
	-- print(headers)
	list_uploads = archive_user_uploads('aitus95')
	for i,v in pairs(list_uploads) do
		print(i,v)
	end
	return true
end
