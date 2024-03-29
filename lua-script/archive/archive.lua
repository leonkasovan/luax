-- Generate DB, search from DB, source from archive.org
-- Source HTM : 
-- https://archive.org/download/nes-roms
-- https://archive.org/download/nes-romset-ultra-us
-- 19:37 22 April 2023, Dhani Novan, Jakarta, Cempaka Putih

-- TODO:
-- Add thumbnail in "open" use "http://thumbnails.libretro.com/" (fix thumbnail - category mapping)
-- Enhance "find" and "open" for 2 keyword (done) and optimize it (done)
-- Enhance "find" and "open" for filtering based on category, sample: "snes:street fighter" (done)
-- Add support read zip compressed db (done)

dofile('../strict.lua')
dofile('../common.lua')

local content_format_zipped = '<tr><td><a href=".-%.zip/(.-)">.-/*(.-)</a><td><td>.-<td id="size">(.-)</tr>'
local content_format_folder = '<td><a href="(.-)">(.-)</a>.-</td>.-<td>.-</td>.-<td>(.-)</td>.-</tr>'
local category_thumbnail = {
	snes = "Nintendo - Super Nintendo Entertainment System",
	nes = "Nintendo - Family Computer Disk System",
	mame = "MAME",
	fbneo = "FBNeo - Arcade Games",
	sega_gen = "Sega - Mega Drive - Genesis",
	psx = "Sony - PlayStation",
	ps2 = "Sony - PlayStation 2",
	ps3 = "Sony - PlayStation 3",
	psp = "Sony - PlayStation Portable",
	neogeo = "SNK - Neo Geo",
	nds = "Nintendo - Nintendo DS",
	n64 = "Nintendo - Nintendo 64",
	gba = "Nintendo - Game Boy Advance",
	["3ds"] = "Nintendo - Nintendo 3DS",
}
	
-- line = "one two three four"
-- keyword = "one" return true
-- keyword = "one two" return true
-- keyword = "one five" return false
-- keyword = "one -four" return false
function find_in_string(line, keyword)
	local found
	local tmp, words
	local low_case_str
	
	if line == nil or keyword == nil or #line == 0 or #keyword == 0 then
		return false
	end
	
	-- split each word in keyword and put in new table with criteria word's length > 0
	if type(keyword) == "string" then
		tmp = csv.parse(keyword:lower(),' ')
		words = {}
		for i,v in pairs(tmp) do
			if #v > 0 then
				words[#words + 1] = v
			end
		end
	else	-- table
		words = keyword
	end
	
	found = true
	low_case_str = line:lower()
	for i,v in pairs(words) do
		if v:sub(1,1) == '-' then	-- process exclude operator
			if low_case_str:find(v:sub(2,-1), 1, true) ~= nil then
				found = found and false
				break	-- shortcut evaluation
			else
				found = found and true
			end
		else -- process normal (include) word
			if low_case_str:find(v, 1, true) ~= nil then
				found = found and true
			else
				found = found and false
				break	-- shortcut evaluation
			end
		end
	end
	return found
end

-- Return table of game category, available in local csv database
function archive_get_local_category()
	local res = {}
	local nn = 0
	
	for file in lfs.dir(".") do
		if file ~= "." and file ~= ".." then
			local attr = lfs.attributes(file)
			local category, line
			if attr.mode == "file" and file:match("%.csv$") then
				local fi = io.open(file, "r")
				if fi then
					-- Read the first line (category)
					line = fi:read("*line")
					category = line:match("^#category=(.-)$")
					if category == nil then
						print(file, "Invalid db. Can't find category")
						print(line)
					else
						if res[category] == nil then
							res[category] = 1
							nn = nn + 1
						else
							res[category] = res[category] + 1
						end
					end
					fi:close()
				end
			end
		end
	end
	print("There are "..tostring(nn).." categories in this local database")
	table.sort(res, function(a, b) return a.key < b.key end)
	return res
end

-- List uploads by user_id
-- Usage: archive_user_uploads('aitus95')
-- success, function return table
-- fail, function return nil
function archive_user_uploads(user)
	local res = {}
	local done = false
	local page = 1
	local user_url
	
	user_url = 'https://archive.org/details/@'..user..'?tab=uploads&page='
	repeat
		print("Processing page "..page)
		local rc, headers, content = http.request(user_url..tostring(page))
		if rc ~= 0 then
			print("Error: "..http.error(rc), rc)
			return nil
		end
		if content:match('class="no%-results"') then
			done = true
		end
		for link in content:gmatch('\n            <a href%="/details/(.-)" title="') do
			res[#res + 1] = link
		end
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
	
	if user_url:find("cylum", 1, true) then
		return cylum_archive_generate_db(user_url, category)
	end
	
	if user_url:find("MAME_2003-Plus_Reference_Set_2018", 1, true) then
		return custom1_archive_generate_db(user_url, category)
	end
	
	if user_url:find("MAME_2016_Arcade_Romsets", 1, true) then
		return custom2_archive_generate_db(user_url, category)
	end
	
	if user_url:find("MAME_2015_arcade_romsets", 1, true) then
		return custom3_archive_generate_db(user_url, category)
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
		or w3:match("%-") or w1:match("^/details/") or w2:match("parent directory")
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

-- fo == nil => console mode
-- fo ~= nil => browser mode
function find_db(fi, no, selected_category, keyword, fo)
	local user_url, folder_id, line, category, f
	
	line = fi:read("*l")
	category = line:match("^#category=(.*)$")
	if category == nil then
		print("Invalid db. Can't find category")
		print(line)
		return no
	end
	
	line = fi:read("*l")
	user_url = line:match('^#url=(.-)$')
	if user_url == nil then
		print("Invalid db. Can't find user_url")
		print(line)
		return no
	else
		if user_url:sub(-1,-1) ~= "/" then
			user_url = user_url.."/"
		end
	end
	folder_id = line:match('download/(.-)/') or line:match('download/(.-)$')
	if user_url == nil then
		print("Invalid db. Can't find folder_id")
		print(line)
		return no
	end
	
	if selected_category == nil or selected_category:find(category,1,true) ~= nil then
		line = fi:read("*l")
		if fo == nil then -- output to console mode
			while line do
				f = csv.parse(line, '|')
				if find_in_string(f[2], keyword) then
					no = no + 1
					print(string.format("[%d] \27[92m%s\27[0m (%s)\n    Size: %s\n    Link: %s%s\n", no, f[2], category, f[3], user_url, f[1]))
				end
				line = fi:read("*l")
			end
		else -- output to html
			while line do
				f = csv.parse(line, '|')
				if find_in_string(f[2], keyword) then
					no = no + 1
					fo:write(string.format("<tr><td align='left'><a href='%s%s'>%s</a><br/><p style='color:#AAAAAA;font-size:9px;'>%s</p><br/><img src='http://thumbnails.libretro.com/%s/Named_Snaps/%s.png'></td><td>%s</td><td><a href='%s'>%s</a></td></tr>\n"
					, user_url, f[1], f[2], f[3], category_thumbnail[category] or "none", f[2], category, user_url, folder_id))
				end
				line = fi:read("*l")
			end
		end	
	end

	return no
end

-- Find in text mode (console)
function archive_find_db(keyword)
	local no = 0	-- counter of data found matched
	local nn = 0	-- line number
	local selected_category = nil

	os.execute("echo")	-- activate color in console (Windows)
	
	-- selected_category is requested
	nn = keyword:find(":")	-- borrow nn variable
	if nn ~= nil then
		selected_category = keyword:match("^(.-)\:")
		keyword = keyword:sub(nn+1)
	end
	
	-- split words in here (not in the loop) for speed up 
	local words = {}
	for i,v in pairs(csv.parse(keyword:lower(),' ')) do
		if #v > 0 then
			words[#words + 1] = v
		end
	end	
	
	for file in lfs.dir(".") do
		if file ~= "." and file ~= ".." then
			local attr = lfs.attributes(file)
			if attr.mode == "file" and file:match("%.csv$") then
				local fi = io.open(file, "r")
				if fi then
					no = find_db(fi, no, selected_category, words)
					fi:close()
				else
					print("[Error] Failed to open csv: "..file)
				end
			elseif attr.mode == "file" and file:match("%.zip$") then
				local zipfile = zip.open(file)
				if zipfile then
					for entry in zipfile:files() do
						local fi = zipfile:open(entry.filename)
						if fi then
							no = find_db(fi, no, selected_category, words)
							fi:close()
						end
					end
					zipfile:close()
				else
					print("[Error] Failed to open the zip archive: "..file)
				end
			end
		end
	end
	print("\n=====================================\nFound "..no.." data")
	return no
end

-- Find, generate HTML output and open it in browser
function archive_find_db_and_open(keyword)
	local f, fo
	local nn = 0
	local selected_category = nil
	-- local lower_keyword = keyword:lower()
	
	-- selected_category is requested
	nn = keyword:find(":")	-- borrow nn variable
	if nn ~= nil then
		selected_category = keyword:match("^(.-)\:")
		keyword = keyword:sub(nn+1)
	end
	
	-- split words in here (not in the loop) for speed up 
	local words = {}
	for i,v in pairs(csv.parse(keyword:lower(),' ')) do
		if #v > 0 then
			words[#words + 1] = v
		end
	end
	
	fo = io.open("result.htm", "w")
	if fo == nil then
		print('Error create file result.htm')
		return false
	end
	
	fo:write([=[
<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
 
<title>Find data archive.org</title>
<style type="text/css"> 
body, html  { height: 100%; }
html, body, div, span, applet, object, iframe,
/*h1, h2, h3, h4, h5, h6,*/ p, blockquote, pre,
a, abbr, acronym, address, big, cite, code,
del, dfn, em, font, img, ins, kbd, q, s, samp,
small, strike, strong, sub, sup, tt, var,
b, u, i, center,
dl, dt, dd, ol, ul, li,
fieldset, form, label, legend,
table, caption, tbody, tfoot, thead, tr, th, td {
	margin: 0;
	padding: 0;
	border: 0;
	outline: 0;
	font-size: 100%;
	vertical-align: baseline;
	background: transparent;
}
body { line-height: 1; }
ol, ul { list-style: none; }
blockquote, q { quotes: none; }
blockquote:before, blockquote:after, q:before, q:after { content: ''; content: none; }
:focus { outline: 0; }
del { text-decoration: line-through; }
table {border-spacing: 0; }
 
/*------------------------------------------------------------------ */
 body{
	font-family:Arial, Helvetica, sans-serif;
	margin:0 auto;
}
a:link {
	color: #666;
	font-weight: bold;
	text-decoration:none;
}
a:visited {
	color: #666;
	font-weight:bold;
	text-decoration:none;
}
a:active,
a:hover {
	color: #bd5a35;
	text-decoration:underline;
}
 
table a:link {
	color: #666;
	font-weight: bold;
	text-decoration:none;
}
table a:visited {
	color: #999999;
	font-weight:bold;
	text-decoration:none;
}
table a:active,
table a:hover {
	color: #bd5a35;
	text-decoration:underline;
}
table {
	font-family:Arial, Helvetica, sans-serif;
	font-size:12px;
	margin:20px;
	border: 1px solid;
}
table th {
	padding:10px 25px 10px 25px; 
	background: #000000	;
	border-left: 1px solid #a0a0a0;
	color:#ffffff;
}
table th:first-child {
	border-left: 0;
}
table tr {
	text-align: center;
	padding-left:20px;
}
table td:first-child {
	padding-left:20px;
	border-left: 0;
}
table td {
	padding:10px;
	border-top: 0px solid #ffffff;
	border-bottom:1px solid #a0a0a0;
	border-left: 1px solid #a0a0a0;
	
	background: #ffffff;
}
table tr.even td {
	background: #eeeeee;
}
table tr:hover td {
	background: #bbbbff;
}
table td.minus {
	color: #ff0000;
}
table td.plus {
	color: #008800;
} 
</style>
 </head>
 <body>
 <h2>&nbsp;&nbsp;&nbsp;Search result</h2>
 <table cellspacing='0'>
	<thead>
		<tr>
			<th>Title</th>
			<th>System</th>
			<th>Collection</th>
		</tr>
	</thead>
	<tbody>
]=])
	local no = 0
	for file in lfs.dir(".") do
		if file ~= "." and file ~= ".." then
			local attr = lfs.attributes(file)
			if attr.mode == "file" and file:match("%.csv$") then
				local fi = io.open(file, "r")
				if fi then
					no = find_db(fi, no, selected_category, words, fo)
					fi:close()
				else
					print("[Error] Failed to open csv: "..file)
				end
			elseif attr.mode == "file" and file:match("%.zip$") then
				local zipfile = zip.open(file)
				if zipfile then
					for entry in zipfile:files() do
						local fi = zipfile:open(entry.filename)
						if fi then
							no = find_db(fi, no, selected_category, words, fo)
							fi:close()
						end
					end
					zipfile:close()
				else
					print("[Error] Failed to open the zip archive: "..file)
				end
			end
		end
	end
	fo:write([=[
	</tbody>
 </table>
 <hr>
 <div align='center' style='font-size:smaller'><br>Copyright &copy;2013, <b>Dhani Novan</b> (dhani.novan@gmail.com)</div><br/>
</body>
</html>
]=])
	fo:close()
	print("\n=====================================\nFound "..no.." data")
	return no
end

-- url=https://archive.org/download/cylums-snes-rom-collection/Gamelist.txt
-- url=https://archive.org/download/cylums-final-burn-neo-rom-collection/Gamelist.txt
-- return table of game list
function cylum_load_gamelist(url)
	local game_list, no, format_gamelist
	
	print("Downloading Gamelist.txt ...")
	local rc, headers, content = http.request(url)
	if rc ~= 0 then
		print("Error: "..http.error(rc), rc)
		return nil
	end
	
	print("Importing Gamelist.txt ...")
	game_list = {}
	no = 0
	format_gamelist = nil
	for line in content:gmatch("[^\r\n]+") do
		local game_id, game_year, game_publisher, game_genre, game_player, game_title
		if #line > 60 then
			if format_gamelist == nil then	-- guess gamelist format: 5 coloumn or 6 coloumn
				game_id, game_year, game_publisher, game_genre, game_player, game_title = line:match("(.-) %-* (%w-) %-%- (.-) %-%-%-* (.-) %-%-%-* (.-) %-%-%-* (.-)$")
				if game_title ~= nil then
					format_gamelist = 6
				else
					game_year, game_publisher, game_genre, game_player, game_title = line:match("(.-) %-%- (.-) %-%-%-* (.-) %-%-%-* (.-) %-%-%-* (.-)$")
					if game_title ~= nil then
						format_gamelist = 5
						game_id = game_title:gsub(" %(also.-%)","")
						game_id = game_id:gsub(":"," -")
						game_id = game_id:gsub("/","-")
					else
						print("Error Gamelist Format. Not 5 and not 6")
						return nil
					end
				end
				print("Gamelist Format: "..tostring(format_gamelist))
			elseif format_gamelist == 5 then
				game_year, game_publisher, game_genre, game_player, game_title = line:match("(.-) %-%- (.-) %-%-%-* (.-) %-%-%-* (.-) %-%-%-* (.-)$")
				if game_title ~= nil then
					game_id = game_title:gsub(" %(also.-%)","")
					game_id = game_id:gsub(":"," -")
					game_id = game_id:gsub("/","-")
				end
			elseif format_gamelist == 6 then
				game_id, game_year, game_publisher, game_genre, game_player, game_title = line:match("(.-) %-* (%w-) %-%- (.-) %-%-%-* (.-) %-%-%-* (.-) %-%-%-* (.-)$")
			end
			if game_title == nil then
				-- print("\tInvalid gamelist data: ", line)
			else
				game_list[game_id] = {game_year, game_publisher, game_genre, game_player, game_title}
				no = no + 1
			end
		end
	end
	print("Gamelist Result: "..tostring(no))
	return game_list
end

-- user_url=https://archive.org/download/cylums-final-burn-neo-rom-collection/Cylum%27s%20FinalBurn%20Neo%20ROM%20Collection%20%2802-18-21%29/
-- user_url=https://archive.org/download/cylums-snes-rom-collection/Cylum%27s%20SNES%20ROM%20Collection%20%2802-14-2021%29.zip/
-- user_url=https://archive.org/download/cylums-snes-rom-collection
function cylum_archive_generate_db(user_url, category)
	local fo, output_fname, rc, headers, content, nn, list, game_data, content_format,w1,w2,w3, user_url2
	
	if user_url == "" or user_url == nil then
		return false
	end
	
	print("\nProcess url: "..user_url)
	category = category or "general"
	
	if user_url:sub(-1,-1) == "/" then	-- request 2 level url "https://archive.org/download/cylums-snes-rom-collection/Cylum%27s%20SNES%20ROM%20Collection%20%2802-14-2021%29.zip/"
		user_url2 = user_url
		output_fname = user_url:match('download/(.-)/')
	else -- request 1 level url "https://archive.org/details/cylums-snes-rom-collection"
		if user_url:match('/details/') then
			user_url = user_url:gsub('/details/','/download/')
			output_fname = user_url:match('download/(.-)$')
		elseif user_url:match('/download/') then
			output_fname = user_url:match('download/(.-)$')
		else
			output_fname = user_url
			user_url = 'https://archive.org/download/'..user_url
		end
		
		content_format = nil
		rc, headers, content = http.request(user_url)
		if rc ~= 0 then
			print("Error: "..http.error(rc), rc)
			return false
		end
		
		-- guess content format based on url found
		for link,desc in content:gmatch('<td><a href="(.-)">(.-)</a>') do
			if desc:sub(-1,-1) == "/" then
				-- print(link,desc)
				print("Content format: folder")
				content_format = content_format_folder
				user_url2 = user_url.."/"..link
			elseif desc:sub(-4,-1) == ".zip" then
				-- print(link,desc)
				print("Content format: zipped")
				content_format = content_format_zipped
				user_url2 = user_url.."/"..link.."/"
			end
		end	
	end
	
	if output_fname == nil then
		print("Error input url.\nExample: https://archive.org/download/cylums-final-burn-neo-rom-collection/Cylum%27s%20FinalBurn%20Neo%20ROM%20Collection%20%2802-18-21%29/")
		return false
	end
	list = cylum_load_gamelist("https://archive.org/download/"..output_fname.."/Gamelist.txt")
	if list == nil then
		return false
	end
	
	print("Downloading database content from url2...")
	print("url2: "..user_url2)
	rc, headers, content = http.request(user_url2)
	if rc ~= 0 then
		print("Error: "..http.error(rc), rc)
		return false
	end

	if content_format == nil then
		local title
		title = content:match("<title>(.-)</title>"):sub(-7,-1)	-- guess content format based on TITLE
		if title == "Archive" then
			print("Content format: zipped")
			content_format = content_format_zipped
		elseif title == "listing" then
			print("Content format: folder")
			content_format = content_format_folder
		else
			print('Error unknown content format: not zipped and not folder')
			return false
		end
	end

	-- count char / in user_url2 to generate output_fname (special for sub folder)
	local charcount = 0
	for i=1, #user_url2 do
		if user_url2:sub(i, i) == "/" then
			charcount = charcount + 1
		end
	end
	
	if charcount == 7 then	-- process sub folder
		local subfolder = user_url2:match(".*/(.-)/$")
		subfolder = subfolder:gsub('%%(%x%x)', function(hex)
			return string.char(tonumber(hex, 16))
		end)
		subfolder = subfolder:gsub("%W","_")
		
		output_fname = output_fname:gsub("%W","_").."_"..subfolder..".csv"
	else -- process base folder
		output_fname = output_fname:gsub("%W","_")..".csv"
	end

	print("Generating database "..output_fname.." ...")
	fo = io.open(output_fname, "w")
	if fo == nil then
		print('Error open a file '..output_fname)
		return false
	end	
	fo:write("#category="..category.."\n")
	fo:write("#url="..user_url2.."\n")
	nn = 0
	for w1,w2,w3 in content:gmatch(content_format) do
		if w1:match("%.jpg$") or w1:match("%.torrent$") or w1:match("%.xml$") or w1:match("%.sqlite$") 
		or w1:match("^/details/") or w2:match("parent directory")
		then
			-- print("\tIgnore: ", w1)
		elseif w3:match("%-") then
			print("Process sub folder: "..w1)
			cylum_archive_generate_db(user_url2..w1, category)
		else
			w2 = w2:gsub("&amp;", "&")
			w2 = w2:gsub("%.%w+$", "")
			w2 = w2:gsub(".-/", "")
			-- print("w2: ", w2)
			game_data = list[w2]
			if is_string_all_digit(w3) then
				w3 = format_bytes(w3)
			end
			if game_data == nil then
				fo:write(string.format("%s|%s|%s\n",w1, w2, w3))
			else
				fo:write(string.format("%s|%s|%s - %s/%s - (c)%s %s\n", w1, game_data[5], w3, game_data[3], game_data[4], game_data[1], game_data[2]))
			end
			nn = nn + 1
		end
	end
	fo:close()
	print("Result created db: "..nn.."\n")
	return true
end

-- user_url=https://archive.org/details/MAME_2003-Plus_Reference_Set_2018
function custom1_archive_generate_db(user_url, category)
	local fo, output_fname, rc, headers, content, nn, game_data, content_format,w1,w2,w3, user_url2
	
	
	if user_url == "" or user_url == nil then
		return false
	end
	
	print("\n[custom1] Process url: "..user_url)
	category = category or "mame"
	
	user_url2 = "https://archive.org/download/MAME_2003-Plus_Reference_Set_2018/roms/"
	content_format = content_format_folder
	output_fname = "MAME_2003-Plus_Reference_Set_2018"
	
	print("Downloading Gamelist DAT.xml ...")
	rc, headers, content = http.request("https://archive.org/download/MAME_2003-Plus_Reference_Set_2018/MAME%202003-Plus%20-%202018-12-31.xml")
	if rc ~= 0 then
		print("Error: "..http.error(rc), rc)
		return false
	end
	local list = {}
	local no = 0
	local game_id,game_title,game_year,game_publisher,game_player
	for game_content in content:gmatch('<game name.-</game>') do
		game_id = game_content:match('game name="(.-)"')
		game_title = game_content:match('<description>(.-)</description>'):gsub("&amp;", "&")
		game_year = game_content:match('<year>(.-)</year>') or '19xx'
		game_publisher = game_content:match('<manufacturer>(.-)</manufacturer>'):gsub("&lt;", "<"):gsub("&gt;", ">")
		game_player = game_content:match('players="(.-)"')
		list[game_id] = {game_year, game_publisher, game_player, game_title}
		no = no + 1
	end
	content = nil
	print("Gamelist Result: "..tostring(no))
		
	print("Downloading database content ...")
	rc, headers, content = http.request(user_url2)
	if rc ~= 0 then
		print("Error: "..http.error(rc), rc)
		return false
	end
	
	output_fname = output_fname:gsub("%W","_")..".csv"

	print("Generating database "..output_fname.." ...")
	fo = io.open(output_fname, "w")
	if fo == nil then
		print('Error open a file '..output_fname)
		return false
	end	
	fo:write("#category="..category.."\n")
	fo:write("#url="..user_url2.."\n")
	nn = 0
	for w1,w2,w3 in content:gmatch(content_format) do
		if w3:match("%-") or w1 == "../" then	-- skip these
			-- print("Ignore subfolder: "..w1)
		else
			w2 = w2:gsub("&amp;", "&")
			w2 = w2:gsub("%.%w+$", "")
			w2 = w2:gsub(".-/", "")
			-- print("w2: ", w2)
			game_data = list[w2:gsub("%.zip$","")]
			if is_string_all_digit(w3) then
				w3 = format_bytes(w3)
			end
			if game_data == nil then
				fo:write(string.format("%s|%s|%s\n",w1, w2, w3))
				print(w2)
			else
				fo:write(string.format("%s|%s|%s - %sp - (c)%s %s\n", w1, game_data[4], w3, game_data[3], game_data[1], game_data[2]))
			end
			nn = nn + 1
		end
	end
	fo:close()
	print("Result created db: "..nn.."\n")
	return true
end

-- user_url=https://archive.org/download/MAME_2016_Arcade_Romsets
-- user_url=https://archive.org/details/MAME_2016_Arcade_Romsets
function custom2_archive_generate_db(user_url, category)
	local fo, output_fname, rc, headers, content, nn, list, game_data, content_format, user_url2
	
	if user_url == "" or user_url == nil then
		return false
	end
	
	print("\n[custom2] Process url: "..user_url)
	category = category or "mame"
	
	user_url2 = "https://archive.org/download/MAME_2016_Arcade_Romsets/roms.zip/"
	output_fname = "MAME_2016_Arcade_Romsets"
	content_format = content_format_zipped
	
	print("Downloading Gamelist DAT.xml ...")
	-- http.set_conf(http.OPT_TIMEOUT, 180)
	-- http.set_conf(http.OPT_NOPROGRESS, false)
	-- rc, headers, content = http.request("https://archive.org/download/MAME_2016_Arcade_Romsets/MAME%202016%20XML%20%28Arcade%20Only%29.xml")
	-- http.set_conf(http.OPT_NOPROGRESS, true)
	-- if rc ~= 0 then
		-- print("Error: "..http.error(rc), rc)
		-- return false
	-- end
	content = load_file("gamedat2016.xml")
	local list = {}
	local no = 0
	local game_id,game_title,game_year,game_publisher, runnable
	for game_content in content:gmatch('<machine name.-</machine>') do
		game_id = game_content:match('machine name="(.-)"')
		game_title = game_content:match('<description>(.-)</description>')
		game_year = game_content:match('<year>(.-)</year>') or '19__'
		game_publisher = game_content:match('<manufacturer>(.-)</manufacturer>') or 'unknown'
		runnable = game_content:find('runnable', 1, true)
		if runnable == nil then
			game_title = game_title:gsub("&amp;", "&")
			game_publisher = game_publisher:gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&amp;", "&")
			list[game_id] = {game_year, game_publisher, game_title}
			no = no + 1
		end
	end
	content = nil
	print("Gamelist Result: "..tostring(no))
	
	print("Downloading database content ...")
	rc, headers, content = http.request(user_url2)
	if rc ~= 0 then
		print("Error: "..http.error(rc), rc)
		return false
	end

	output_fname = output_fname:gsub("%W","_")..".csv"
	
	print("Generating database "..output_fname.." ...")
	fo = io.open(output_fname, "w")
	if fo == nil then
		print('Error open a file '..output_fname)
		return false
	end	
	fo:write("#category="..category.."\n")
	fo:write("#url="..user_url2.."\n")
	nn = 0
	for w1,w2,w3 in content:gmatch(content_format) do
		if w3 == "" then	-- skip these
			-- skip
		else
			w2 = w2:gsub("&amp;", "&")
			w2 = w2:gsub("%.%w+$", "")
			w2 = w2:gsub(".-/", "")
			-- print("w2: ", w2)
			game_data = list[w2:gsub("%.zip$","")]
			if is_string_all_digit(w3) then
				w3 = format_bytes(w3)
			end
			if game_data == nil then
				fo:write(string.format("%s|%s|%s\n",w1, w2, w3))
				print(w2)
			else
				fo:write(string.format("%s|%s|%s - (c)%s %s\n", w1, game_data[3], w3, game_data[1], game_data[2]))
			end
			nn = nn + 1
		end
	end
	fo:close()
	print("Result created db: "..nn.."\n")
	return true
end

-- user_url=https://archive.org/download/MAME_2015_arcade_romsets
-- user_url=https://archive.org/details/MAME_2015_arcade_romsets
function custom3_archive_generate_db(user_url, category)
	local fo, output_fname, rc, headers, content, nn, list, game_data, content_format, user_url2
	
	if user_url == "" or user_url == nil then
		return false
	end
	
	print("\n[custom3] Process url: "..user_url)
	category = category or "mame"
	
	user_url2 = "https://archive.org/download/MAME_2015_arcade_romsets/roms.zip/"
	output_fname = "MAME_2015_arcade_romsets"
	content_format = content_format_zipped
	
	print("Downloading Gamelist DAT.xml ...")
	-- http.set_conf(http.OPT_TIMEOUT, 180)
	-- http.set_conf(http.OPT_NOPROGRESS, false)
	-- rc, headers, content = http.request("https://archive.org/download/MAME_2015_arcade_romsets/mame2015.xml")
	-- http.set_conf(http.OPT_NOPROGRESS, true)
	-- if rc ~= 0 then
		-- print("Error: "..http.error(rc), rc)
		-- return false
	-- end
	content = load_file("mame2015.xml")
	local list = {}
	local no = 0
	local game_id,game_title,game_year,game_publisher,game_player,runnable
	for game_content in content:gmatch('<game name.-</game>') do
		game_id = game_content:match('game name="(.-)"')
		game_title = game_content:match('<description>(.-)</description>')
		game_year = game_content:match('<year>(.-)</year>') or '19xx'
		game_publisher = game_content:match('<manufacturer>(.-)</manufacturer>')
		game_player = game_content:match('players="(.-)"')
		runnable = game_content:find('runnable', 1, true)
		if runnable == nil then
			game_title = game_title:gsub("&amp;", "&")
			game_publisher = game_publisher:gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&amp;", "&")
			list[game_id] = {game_year, game_publisher, game_player, game_title}
			no = no + 1
		else
			-- skip
		end
	end
	content = nil
	print("Gamelist Result: "..tostring(no))
	
	print("Downloading database content ...")
	rc, headers, content = http.request(user_url2)
	if rc ~= 0 then
		print("Error: "..http.error(rc), rc)
		return false
	end

	output_fname = output_fname:gsub("%W","_")..".csv"
	
	print("Generating database "..output_fname.." ...")
	fo = io.open(output_fname, "w")
	if fo == nil then
		print('Error open a file '..output_fname)
		return false
	end	
	fo:write("#category="..category.."\n")
	fo:write("#url="..user_url2.."\n")
	nn = 0
	for w1,w2,w3 in content:gmatch(content_format) do
		if w3 == "" then	-- skip these
			-- skip
		else
			w2 = w2:gsub("&amp;", "&")
			w2 = w2:gsub("%.%w+$", "")
			w2 = w2:gsub(".-/", "")
			-- print("w2: ", w2)
			game_data = list[w2:gsub("%.zip$","")]
			if is_string_all_digit(w3) then
				w3 = format_bytes(w3)
			end
			if game_data == nil then
				fo:write(string.format("%s|%s|%s\n",w1, w2, w3))
				print(w2)
			else
				fo:write(string.format("%s|%s|%s - %sp - (c)%s %s\n", w1, game_data[4], w3, game_data[3], game_data[1], game_data[2]))
			end
			nn = nn + 1
		end
	end
	fo:close()
	print("Result created db: "..nn.."\n")
	return true
end

local t1 = os.clock()
if #arg == 1 then
	archive_find_db(arg[1])
elseif #arg == 2 then
	if arg[1] == "find" then
		archive_find_db(arg[2])
	elseif arg[1] == "create" then
		archive_generate_db(arg[2])
	elseif arg[1] == "user" then
		local nn = 0
		local list_uploads = archive_user_uploads(arg[2])
		
		if list_uploads == nil then
			print("Try again.")
		else
			for i,v in pairs(list_uploads) do
				print(v)
				nn = nn + 1
			end
			print(string.format("\n\n===========================================================\nFound "..nn.." data.\nUse the result for creating db.\nUsage: #> lua %s create \"[folder-id]\" ", arg[0]))
		end
	elseif arg[1] == "open" then
		if archive_find_db_and_open(arg[2]) then
			os.execute("result.htm")
		end
	end
elseif #arg == 3 then
	if arg[1] == "user" then
		local nn = 0
		local list_uploads = archive_user_uploads(arg[2])
		
		if list_uploads == nil then
			print("Error. Try again.")
		else
			for i,v in pairs(list_uploads) do
				if v:lower():find(arg[3]:lower(),1, true) then
					print(v)
					nn = nn + 1
				end
			end
			print(string.format("\n\n===========================================================\nFound "..nn.." data.\nUse the result for creating db.\nUsage: #> lua %s create \"[folder-id]\" ", arg[0]))
		end
	elseif arg[1] == "create" then
		archive_generate_db(arg[2], arg[3])
	end
else
	 local nn = 0
	 for file in lfs.dir(".") do
		 if file ~= "." and file ~= ".." then
			 local attr = lfs.attributes(file)
			 if attr.mode == "file" and file:match("%.csv$") then
				 nn = nn + 1
			 end
		 end
	 end
	
	print(string.format("Manage(create, find) archieve database from archieve.org.\nLocal database: "..nn.." csv file(s)\n\nUsage: \n\t#> lua %s [keyword] => Find keyword in local database", arg[0]))
	print(string.format("\t#> lua %s find [keyword] => Find keyword in local database", arg[0]))
	print(string.format("\t#> lua %s open [keyword] => Find keyword in local database and open the result via browser", arg[0]))
	print(string.format("\t#> lua %s user [user_id] => List [folder-id] user uploads", arg[0]))
	print(string.format("\t#> lua %s create [url] => Generate local database from url (for general category)", arg[0]))
	print(string.format("\t#> lua %s create [id] => Generate local database from https://archive.org/download/[id]", arg[0]))
	print(string.format("\t#> lua %s create [url] [category]=> Generate local database from url and define its category", arg[0]))
	print("\nSample:")
	print(string.format("\t#> lua %s tekken ", arg[0]))
	print(string.format("\t#> lua %s \"street fighter\" ", arg[0]))
	print(string.format("\t#> lua %s find tekken ", arg[0]))
	print(string.format("\t#> lua %s find \"street fighter\" ", arg[0]))
	print(string.format("\t#> lua %s open tekken ", arg[0]))
	print(string.format("\t#> lua %s open \"street fighter\" ", arg[0]))
	print(string.format("\t#> lua %s user kodi_amp_spmc_canada/samuray433/t_m_c/cylum/aitus95/megaarch1996/emorsso_lim/", arg[0]))
	print(string.format("\t#> lua %s create \"https://archive.org/download/nes-roms\" ", arg[0]))
	print(string.format("\t#> lua %s create \"https://archive.org/details/nes-roms\" ", arg[0]))
	print(string.format("\t#> lua %s create \"https://archive.org/details/nes-roms\" \"nes\"", arg[0]))
	print(string.format("\t#> lua %s create \"nes-roms\" ", arg[0]))
	print(string.format("\t#> lua %s create \"nes-roms\" \"nes\"", arg[0]))
	print(string.format("\t#> lua %s create \"https://archive.org/download/cylums-snes-rom-collection/Cylum%%27s%%20SNES%%20ROM%%20Collection%%20%%2802-14-2021%%29.zip/\" \"snes\"", arg[0]))
	print(string.format("\t#> lua %s create \"https://archive.org/download/cylums-snes-rom-collection\" \"snes\"", arg[0]))
	print(string.format("\t#> lua %s create \"cylums-snes-rom-collection\" \"snes\"", arg[0]))
	print("=================================================\n")

-- archive_generate_db("cylums-nintendo-ds-rom-collection", "nds")
-- archive_generate_db("cylums-nintendo-64-rom-collection", "n64")
-- archive_generate_db("cylums-final-burn-neo-rom-collection", "fbneo")
-- archive_generate_db("cylums-neo-geo-rom-collection", "neogeo")
-- archive_generate_db("cylums-game-boy-advance-rom-collection_202102", "gba")
-- archive_generate_db("cylums-sega-32-x-rom-collection", "sega-32x")
-- archive_generate_db("cylums-sega-game-gear-collection", "sega-gg")
-- archive_generate_db("cylums-sega-master-system-rom-collection", "sega-ms")
-- archive_generate_db("cylums-sega-genesis-rom-collection", "sega-gen")
-- archive_generate_db("cylums-snes-rom-collection", "snes")
-- archive_generate_db("cylums-nes-rom-collection", "nes")
-- archive_generate_db("cylums-playstation-rom-collection", "psx")	-- will fail, caused by inconsistent data source
-- archive_generate_db("https://archive.org/download/cylums-playstation-rom-collection/Cylum%27s%20PlayStation%20ROM%20Collection%20%2802-22-2021%29/", "psx")

-- content = [[
-- PS2_COLLECTION_PART1
-- PS2_COLLECTION_PART2
-- PS2_COLLECTION_PART3
-- PS2_COLLECTION_PART4
-- PS2_COLLECTION_PART5
-- PS2_COLLECTION_PART8
-- PS2_COLLECTION_PART9
-- PS2_COLLECTION_PART10
-- PS2_COLLECTION_PART11
-- PS2_COLLECTION_PART12
-- PS2_COLLECTION_PART13
-- PS2_COLLECTION_PART14
-- PS2_COLLECTION_PART15
-- PS2_COLLECTION_PART16
-- PS2_COLLECTION_PART17
-- PS2_COLLECTION_PART18
-- PS2_COLLECTION_PART19
-- PS2_COLLECTION_PART20
-- PS2_COLLECTION_PART21
-- PS2_COLLECTION_PART22
-- PS2_COLLECTION_PART23
-- PS2_COLLECTION_PART24
-- PS2_COLLECTION_PART25
-- PS2_COLLECTION_PART26
-- PS2_COLLECTION_PART27
-- PS2_DEMO_EU
-- ps2_collection_part6_202008
-- ps2_collection_part7
-- ]]

-- for line in content:gmatch("[^\r\n]+") do
	-- print(line)
	-- archive_generate_db(line,"ps2")
-- end

-- for i,v in pairs(archive_get_local_category()) do
	-- print(i,v)
-- end
end
print('Done in '..(os.clock()-t1)..' seconds')
