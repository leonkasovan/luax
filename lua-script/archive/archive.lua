-- Generate DB, search from DB, source from archive.org
-- Source HTM : 
-- https://archive.org/download/nes-roms
-- https://archive.org/download/nes-romset-ultra-us
-- 19:37 22 April 2023, Dhani Novan, Jakarta, Cempaka Putih

dofile('../strict.lua')

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

function archive_find_db_and_open(keyword)
	local f, fo
	local nn = 0
	local lower_keyword = keyword:lower()
	
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
			<th>Size</th>
			<th>Upload Folder</th>
			<th>Direct<br/>Download</th>
		</tr>
	</thead>
	<tbody>
]=])
	for file in lfs.dir(".") do
		if file ~= "." and file ~= ".." then
			local attr = lfs.attributes(file)
			local category
			local folder_id
			local user_url
			
			if attr.mode == "file" and file:match("%.csv$") then
				nn = 0
				for line in io.lines(file) do
					nn = nn + 1
					if nn == 1 then 
						category = line:match("^#category=(.-)$")
						if category == nil then
							print(file, "Invalid db. Can't find category")
							return false
						end
					elseif nn == 2 then
						user_url = line:match('^#url=(.-)$')
						folder_id = line:match('download/(.-)$')	-- ini buat apa? bisa di delete
						if user_url == nil or folder_id == nil then
							print("Invalid db. Can't find user_url or folder_id")
							return false
						end
					else
						if line:byte(1) ~= 35 and line ~= "" then
							f = csv.parse(line, '|')
							if (f[2]:lower()):find(lower_keyword, 1, true) ~= nil then
								if user_url == nil then print("user_url=nil", line) end
								fo:write("<tr><td>"..f[2].."</td><td align='right'>"..f[3].."</td><td><a href='"..user_url.."'>"..folder_id.."</a></td><td><a href='"..user_url.."/"..f[1].."'>DL</a></td></tr>\n")
							end
						end
					end
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
	return true
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
				print("\tGamelist Format: "..tostring(format_gamelist))
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
	print("\tResult: "..tostring(no))
	return game_list
end

-- user_url=https://archive.org/download/cylums-final-burn-neo-rom-collection/Cylum%27s%20FinalBurn%20Neo%20ROM%20Collection%20%2802-18-21%29/
-- user_url=https://archive.org/download/cylums-snes-rom-collection/Cylum%27s%20SNES%20ROM%20Collection%20%2802-14-2021%29.zip/
function cylum_archive_generate_db(user_url, category)
	local fo, output_fname, rc, headers, content, nn, list, game_data, content_format,w1,w2,w3
	if user_url == "" or user_url == nil then
		return false
	end
	
	category = category or "general"
	output_fname = user_url:match('download/(.-)/')
	if output_fname == nil then
		print("Error input url.\nExample: https://archive.org/download/cylums-final-burn-neo-rom-collection/Cylum%27s%20FinalBurn%20Neo%20ROM%20Collection%20%2802-18-21%29/")
		return false
	end
	list = cylum_load_gamelist("https://archive.org/download/"..output_fname.."/Gamelist.txt")
	if list == nil then
		return false
	end
	
	print("Downloading database content ...")
	rc, headers, content = http.request(user_url)
	if rc ~= 0 then
		print("Error: "..http.error(rc), rc)
		return false
	end

	print("Generating database "..output_fname.." ...")	
	content_format = nil
	w3 = content:match("<title>(.-)</title>"):sub(-7,-1)	-- guess content format based on TITLE
	if w3 == "Archive" then
		print("\tContent format: zipped")
		content_format = '<tr><td><a href=".-%.zip/(.-)">.-/*(.-)</a><td><td>.-<td id="size">(.-)</tr>'
	elseif w3 == "listing" then
		print("\tContent format: folder")
		content_format = '<td><a href="(.-)">(.-)</a>.-</td>.-<td>.-</td>.-<td>(.-)</td>.-</tr>'
	else
		print('Error unknown content format: not zipped and not folder')
		return false
	end

	output_fname = output_fname:gsub("%W","_")..".csv"
	fo = io.open(output_fname, "w")
	if fo == nil then
		print('Error open a file '..output_fname)
		return false
	end	
	fo:write("#category="..category.."\n")
	fo:write("#url="..user_url.."\n")
	nn = 0
	for w1,w2,w3 in content:gmatch(content_format) do
		if w1:match("%.jpg$") or w1:match("%.torrent$") or w1:match("%.xml$") or w1:match("%.sqlite$") 
		or w3:match("%-") or w1:match("^/details/") or w2:match("parent directory")
		then
			print("\tIgnore: ", w1)
		else
			w2 = w2:gsub("&amp;", "&")
			w2 = w2:gsub("%.%w+$", "")
			w2 = w2:gsub(".-/", "")
			-- print("w2: ", w2)
			game_data = list[w2]
			if game_data == nil then
				fo:write(string.format("%s|%s|%s\n",w1, w2, w3))
			else
				fo:write(string.format("%s|%s|%s - %s/%s - (c)%s %s\n", w1, game_data[5], w3, game_data[3], game_data[4], game_data[1], game_data[2]))
			end
			nn = nn + 1
		end
	end
	fo:close()
	print("\tResult: "..nn.."\n")
	return true
end

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
			-- os.execute("del result.htm")
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
	print(string.format("\t#> lua %s create [url] => Generate local database from url", arg[0]))
	print(string.format("\t#> lua %s create [id] => Generate local database from https://archive.org/download/[id]", arg[0]))
	print(string.format("\t#> lua %s create [url] [category]=> Generate local database from url and define its category", arg[0]))
	print("\nSample:")
	print(string.format("\t#> lua %s tekken ", arg[0]))
	print(string.format("\t#> lua %s \"street fighter\" ", arg[0]))
	print(string.format("\t#> lua %s find tekken ", arg[0]))
	print(string.format("\t#> lua %s find \"street fighter\" ", arg[0]))
	print(string.format("\t#> lua %s open tekken ", arg[0]))
	print(string.format("\t#> lua %s open \"street fighter\" ", arg[0]))
	print(string.format("\t#> lua %s user aitus95", arg[0]))
	print(string.format("\t#> lua %s user cylum", arg[0]))
	print(string.format("\t#> lua %s user t_m_c", arg[0]))
	print(string.format("\t#> lua %s user kodi_amp_spmc_canada", arg[0]))
	print(string.format("\t#> lua %s create \"https://archive.org/download/nes-roms\" ", arg[0]))
	print(string.format("\t#> lua %s create \"https://archive.org/details/nes-roms\" ", arg[0]))
	print(string.format("\t#> lua %s create \"https://archive.org/details/nes-roms\" \"NES\"", arg[0]))
	print(string.format("\t#> lua %s create \"nes-roms\" ", arg[0]))
	
	-- Test user Cylum database
	-- cylum_archive_generate_db("https://archive.org/download/cylums-final-burn-neo-rom-collection/Cylum%27s%20FinalBurn%20Neo%20ROM%20Collection%20%2802-18-21%29/", "fbneo")
	
	-- content = [[
-- PS3_GAMES_AITUS
-- PS3_GAMES_AITUS_2
-- PS3_GAMES_AITUS_OTHER
-- PS3_PSN_1
-- PS3_PSN_2
-- ]]

	-- for line in content:gmatch("[^\r\n]+") do
		-- print(line)
		-- archive_generate_db(line,"PS3")
	-- end
	return true
end
