-- LUA Library : Download file from Google Drive
-- Format Input URL = 
--			https://drive.google.com/uc?id=<<FILE_ID>>&export=download
--			https://drive.google.com/file/d/<<FILE_ID>>/view?usp=sharing
-- Interpreter : luaX https://drive.google.com/file/d/1gaDQVusrvp78HfQbswVx4Wr-4-plA4Ke/view?usp=sharing
-- 13:25 16 Jan 2021, Rawamangun
require('strict')

-- GLOBAL SETTING
local TEMP_FILE = "file.tmp"
local MAXTIMEOUT = 3600	-- set max timeout 30 minutes
local LOG_FILE = "gdrive.log"
-- local DEBUG = true	-- write all log to a file (LOG_FILE)
local DEBUG = false	-- write all log to console output

function format_number(s)
    local pos = string.len(s) % 3

    if pos == 0 then pos = 3 end
    return string.sub(s, 1, pos).. string.gsub(string.sub(s, pos+1), "(...)", ".%1")
end

function my_write_log(data)
	local fo
	if DEBUG then 
		fo = io.open(LOG_FILE, "a")
		if fo == nil then
			print("Can not open "..LOG_FILE)
			return nil
		end
		fo:write(table.concat{os.date(), " ", data, "\n"})
		fo:close()
		return true
	else
		print(os.date()..data)
		return true
	end
end

function save_file(content, filename)
	local fo
	
	fo = io.open(filename, "w")
	fo:write(content)
	fo:close()
end

function load_file(filename)
	local fi, content

	fi = io.open(filename, "r")
	if fi == nil then
		write_log("[error][gdrive.load_file] Can't open "..filename)
		return nil
	end
	content = fi:read("*a")
	fi:close()
	return content
end

-- Output :
--	true : on success
--	false : fail, timeout or network problem (can be retried)
--	nil : fail, invalid response
function download_gdrive(url, callback_function_write_log, callback_function_on_success)
	local rc, content, header, filename, id, direct_url, original_url, n
	local i, v, links
	local write_log
 
	if callback_function_write_log ~= nil then
		write_log = callback_function_write_log
	else
		write_log = my_write_log
	end
	
	write_log('[info][gdrive] Processing '..url)
	original_url = url
	id = string.match(url, '/%w/(.-)/view')
	if id ~= nil then
		url = 'https://drive.google.com/uc?id='..id..'&export=download'
	end
	
	http.set_conf(http.OPT_COOKIEFILE, "gdrive_cookies.txt")
	os.remove(TEMP_FILE)
	rc, header = http.request{url = url, output_filename = TEMP_FILE}
	if rc ~= 0 then
		write_log("[error][gdrive.1] "..http.error(rc))
		os.remove(TEMP_FILE)
		return nil
	end
	
	filename = string.match(header, 'filename="(.-)"')
	if filename ~= nil then
		filename = filename:gsub('[%/%\%:%?%*%"%<%>%|]', "")
		os.rename(TEMP_FILE, filename)
		os.remove(TEMP_FILE)
		-- Update success list of URL
		if callback_function_on_success ~= nil then 
			callback_function_on_success(string.format("%s %s; %s (%s bytes)", os.date(), original_url, filename, format_number(os.getfilesize(filename))))
		end
		write_log(string.format("[info][gdrive] Success saving (small) file '%s' (%s bytes)", filename, format_number(os.getfilesize(filename))))
		return true
	end
	
	-- Extract Filename
	content = load_file(TEMP_FILE)
	os.remove(TEMP_FILE)
	filename = string.match(content, '<a href=".-">(.-)</a>')
	if filename == nil then
		write_log("[error][gdrive.2] Can't find it's filename. Invalid response from Google Drive")
		save_file(content,"gdrive_invalid_content.htm")
		return nil
	end
	filename = filename:gsub('[%/%\%:%?%*%"%<%>%|]', "")
 
	direct_url = nil
	links = http.collect_link(content, url)
	for i, v in ipairs(links) do
		if string.find(v, "confirm=") then
			direct_url = v
		end
	end
 
	if direct_url == nil then
		save_file(content,"gdrive_invalid_content.htm")
		write_log("[error][gdrive.3] Can't find direct link to download. Invalid response from Google Drive")
		return nil
	end
 
	direct_url = direct_url:gsub( "&amp;", "&")
	write_log('[info][gdrive] Request direct URL '..direct_url)
	http.set_conf(http.OPT_REFERER, url)
	http.set_conf(http.OPT_TIMEOUT, MAXTIMEOUT)
	rc, header = http.request{url = direct_url, output_filename = TEMP_FILE}
	if rc ~= 0 then
		write_log("[error][gdrive.4] "..http.error(rc), rc)
		os.remove(TEMP_FILE)
		return nil
	end
	

	-- Extract Filename
	content = load_file(TEMP_FILE)
	os.remove(TEMP_FILE)
	filename = string.match(content, '<a href=".-">(.-)</a>')
	if filename == nil then
		write_log("[error][gdrive.5] Can't find it's filename. Invalid response from Google Drive")
		save_file(content,"gdrive_invalid_content.htm")
		return nil
	end
	filename = filename:gsub('[%;%#%/%\%:%?%*%"%<%>%|]', "")
 
	direct_url = nil
	links = http.collect_link(content, url)
	for i, v in ipairs(links) do
		if string.find(v, "confirm=") then
			direct_url = v
		end
	end
 
	if direct_url == nil then
		save_file(content,"gdrive_invalid_content.htm")
		write_log("[error][gdrive.6] Can't find direct link to download. Invalid response from Google Drive")
		return nil
	end
 
	direct_url = direct_url:gsub( "&amp;", "&")
	write_log('[info][gdrive] Downloading '..filename..' from '..format_number(os.getfilesize(filename)))
	http.set_conf(http.OPT_REFERER, url)
	http.set_conf(http.OPT_TIMEOUT, MAXTIMEOUT)
	rc = 0
	n = 0
	repeat
		if rc ~= 0 then write_log('[error][gdrive.7] Retry '..n..': resuming downloading '..filename..' from '..format_number(os.getfilesize(filename))) end
		rc, header = http.request{url = direct_url, output_filename = filename}
		n = n + 1
	until rc ~= 28	-- until not time out (return code = 28)
	if rc ~= 0 then
		write_log("[error][gdrive.8] "..http.error(rc)..". Downloaded: "..format_number(os.getfilesize(filename)).." bytes")
		return false
	end
	
	-- Update success list of URL
	if callback_function_on_success ~= nil then
		callback_function_on_success(string.format("%s %s; %s (%s bytes)", os.date(), original_url, filename, format_number(os.getfilesize(filename))))
	end
	write_log(string.format("[info][gdrive] Success saving (big) file '%s' (%s bytes)", filename, format_number(os.getfilesize(filename))))
	return true
end

function verify_gdrive(url)
	return url:match('https://drive%.google%.com/file/%w/.-/view') 
		or url:match('https://drive%.google%.com/uc%?id=.-&export=download')
end

-------------------------------------------------------------------------------
--	Library Testing
--	Method 1:
--	local gdrive = dofile('gdrive.lua')

--	Method 2:
--function import_library(url)
--	local rc, code

--	rc, code = http.get_url(url)
--	if rc ~= 0 then
--		write_log("[error][import_library] "..http.error(rc))
--		return nil
--	end
--	return loadstring(code)()
--end
--local gdrive = import_library('https://gist.github.com/dhaninovan/d94d938e96b3171a42e47aa1f8c0c22b/raw/f0d1d427e8cfe70884ad3621e084b1341fa05786/gdrive.lua')
-------------------------------------------------------------------------------
-- https://drive.google.com/file/d/1tX99mPnKbK3LoFMWhgPQ3fkJIl1-lTOP/view --Little Nightmare 2
-- https://drive.google.com/file/d/1I9mp4wQ1HqTf2bqf02mLBbDDewq54YGE/view -- The room 4 part 1
-- https://drive.google.com/file/d/1bD0Htxf0PA9H6amkdpGjcs5BwPgAbg4U/view -- The room 4 part 2
-- https://drive.google.com/file/d/1MFpdoyxwDkUX72IwdG8iRR2f2HiUuov9/view	Gi Joe Part 1
-- https://drive.google.com/file/d/1tRsLrRhXGKZbqwV1R5MOlpf6o4-cUvU3/view	Jet cave Adventure

-- Movie Finding Ohana
content = [[
https://drive.google.com/uc?id=1kgzgnYfTnogMcXkrVIuaA8l3-RLkWB1K&export=download
]]

for url in content:gmatch("[^\r\n]+") do
	if verify_gdrive(url) then
		res = download_gdrive(url)
	else
		my_write_log('[error][gdrive] invalid URL')
	end
end

local MAXTRY = 10
for url in content:gmatch("[^\r\n]+") do
	--if gdrive.verify(url) then
	if verify_gdrive(url) then
		--done = gdrive.download(url, my_write_log, print)
		done = download_gdrive(url)
		try = 1
		while ((try <= MAXTRY) and (done == false)) do
			write_log('Retry '..try)
			--done = gdrive.download(url)
			done = download_gdrive(url)
			try = try + 1
		end
	else
		print('URL not valid for Google Drive')
	end
end

-------------------------------------------------------------------------------
--	Library Interface
-------------------------------------------------------------------------------
return {
	download = download_gdrive,
	verify = verify_gdrive
}

