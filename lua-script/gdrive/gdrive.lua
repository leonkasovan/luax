-- LUA Library : Download file from Google Drive
-- Format Input URL = 
--			https://drive.google.com/uc?id=<<FILE_ID>>&export=download
--			https://drive.google.com/uc?id=1Kbj6fGAWZCWsCBjmkPf-sN-lfzqBMJww&export=download
--			https://drive.google.com/file/d/<<FILE_ID>>/view?usp=sharing
-- Interpreter : modified lua https://drive.google.com/file/d/1imqMbflxEEc8OsTCJoHiuMufdAfJTNSg/view?usp=drivesdk
-- 17:21 16 May 2020, Rawamangun

-- GLOBAL SETTING
local TEMP_FILE = "file.tmp"
local MAXTIMEOUT = 1200	-- set max timeout 15 minutes
local LOG_FILE = "gdrive.log"
local DEBUG = true	-- write all log to a file (LOG_FILE)
--local DEBUG = false	-- write all log to console output

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
		print(data)
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
	local rc, content, header, filename, id, direct_url, original_url
	local i, v, links
	local write_log
 
	if callback_function_write_log ~= nil then
		write_log = callback_function_write_log
	else
		write_log = my_write_log
	end
	
	original_url = url
	id = string.match(url, '/%w/(.-)/view')
	if id ~= nil then
		url = 'https://drive.google.com/uc?id='..id..'&export=download'
	end
	
	http.set_conf(http.OPT_COOKIEFILE, "gdrive_cookies.txt")
	rc = http.get_url(url, TEMP_FILE)
	if rc ~= 0 then
		write_log("[error][gdrive.download] "..http.error(rc))
		return false
	end
	
	header = load_file('http_header.txt')
	filename = string.match(header, 'filename="(.-)"')
	if filename ~= nil then
		filename = filename:gsub('[%/%\%:%?%*%"%<%>%|]', "")
		os.rename(TEMP_FILE, filename)
		os.remove(TEMP_FILE)
		-- Update success list of URL
		if callback_function_on_success ~= nil then 
			callback_function_on_success(string.format("%s %s; %s (%s bytes) MD5:%s", os.date(), original_url, filename, format_number(os.getfilesize(filename)), os.checksum(filename)))
		end
		write_log(string.format("[info][gdrive.download] Success saving (small) file '%s' (%s bytes) MD5:%s", filename, format_number(os.getfilesize(filename)), os.checksum(filename)))
		return true
	end
	
	-- Extract Filename
	content = load_file(TEMP_FILE)
	filename = string.match(content, '<a href=".-">(.-)</a>')
	if filename == nil then
		write_log("[error][gdrive.download] 1. Can't find it's filename. Invalid response from Google Drive")
		os.rename(TEMP_FILE, "gdrive_invalid_content.htm")	-- harusnya TEMP_FILE hilang
		os.remove(TEMP_FILE)	--tapi kok tidak hilang. jadi dihapus manual
		return nil
	end
	os.remove(TEMP_FILE)
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
		write_log("[error][gdrive.download] 1. Can't find direct link to download. Invalid response from Google Drive")
		return nil
	end
 
	direct_url = direct_url:gsub( "&amp;", "&")
	write_log('[info][gdrive.download] Direct URL '..direct_url)
	http.set_conf(http.OPT_REFERER, url)
	http.set_conf(http.OPT_TIMEOUT, MAXTIMEOUT)
	rc = http.get_url(direct_url, TEMP_FILE)	-- 2x proses, use TEMP
	if rc ~= 0 then
		write_log("[error][gdrive.download] "..http.error(rc))
		return false
	end

	-- Extract Filename
	content = load_file(TEMP_FILE)
	filename = string.match(content, '<a href=".-">(.-)</a>')
	if filename == nil then
		write_log("[error][gdrive.download] 2. Can't find it's filename. Invalid response from Google Drive")
		os.rename(TEMP_FILE, "gdrive_invalid_content.htm")	-- harusnya TEMP_FILE hilang
		os.remove(TEMP_FILE)	--tapi kok tidak hilang. jadi dihapus manual
		return nil
	end
	os.remove(TEMP_FILE)
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
		write_log("[error][gdrive.download] 2. Can't find direct link to download. Invalid response from Google Drive")
		return nil
	end
 
	direct_url = direct_url:gsub( "&amp;", "&")
	write_log('[info][gdrive.download] Direct URL '..direct_url)
	http.set_conf(http.OPT_REFERER, url)
	http.set_conf(http.OPT_TIMEOUT, MAXTIMEOUT)
	rc = http.get_url(direct_url, filename)
	if rc ~= 0 then
		write_log("[error][gdrive.download] "..http.error(rc)..". Downloaded: "..format_number(os.getfilesize(filename)).." bytes")
		return false
	end
	
	-- Update success list of URL
	os.remove(TEMP_FILE)
	if callback_function_on_success ~= nil then
		callback_function_on_success(string.format("%s %s; %s (%s bytes) MD5:%s", os.date(), original_url, filename, format_number(os.getfilesize(filename)), os.checksum(filename)))
	end
	write_log(string.format("[info][gdrive.download] Success saving (big) file '%s' (%s bytes) MD5:%s", filename, format_number(os.getfilesize(filename)), os.checksum(filename)))
	return true
end

function verify_gdrive(url)
	return url:match('https://drive%.google%.com/file/%w/.-/view') 
		or url:match('https://drive%.google%.com/uc%?id=.-&export=download')
end

return {
	download = download_gdrive,
	verify = verify_gdrive
}
