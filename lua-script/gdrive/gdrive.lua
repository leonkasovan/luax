-- LUA Library : Download file from Google Drive
-- Format Input URL = 
--			https://drive.google.com/uc?id=<<FILE_ID>>&export=download
--			https://drive.google.com/file/d/<<FILE_ID>>/view?usp=sharing
-- Interpreter : luaX https://github.com/dhaninovan/luax/releases/download/v5.1.5.77/lua.exe
-- 13:25 16 Jan 2021, Rawamangun

dofile('../strict.lua')
dofile('../common.lua')
local gist = dofile('../github/gist.lua')

function my_write_log(data)
	print(os.date("%d/%m/%Y %H:%M:%S ")..data)
end

-- GLOBAL SETTING
local TEMP_FILE = "file.tmp"
local MAXTIMEOUT = 5400	-- set max timeout 90 minutes

-- Output :
--	true : on success
--	false : fail, timeout or network problem (can be retried)
--	nil : fail, invalid response
function download_gdrive(url, callback_function_write_log, callback_function_on_success)
	local rc, content, header, filename, id, direct_url, original_url, n
	local i, v, links
	local write_log, ct
 
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
	write_log("gdrive.lua: after set_conf string")
	os.remove(TEMP_FILE)
	write_log("gdrive.lua: before set_conf number")
	http.set_conf(http.OPT_TIMEOUT, MAXTIMEOUT)
	write_log("gdrive.lua: after set_conf number")
	rc, header = http.request{url = url, output_filename = TEMP_FILE}
	if rc ~= 0 then
		write_log("[error][gdrive.1] "..http.error(rc))
		os.remove(TEMP_FILE)
		if rc == 28 then return false else return nil end
	end
	
	filename = string.match(header, '[Ff]ilename%s*=%s*"(.-)"')
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
		gist.update('2ff7b7c90cd7f219043bd450b5c1b05e', 'invalid.htm', content, 'Fail match: <a href=".-">(.-)</a>')
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
		write_log("[error][gdrive.3] Can't find direct link to download. Invalid response from Google Drive")
		gist.update('2ff7b7c90cd7f219043bd450b5c1b05e', 'invalid.htm', content, 'Fail match: confirm=')
		return nil
	end
 
	direct_url = direct_url:gsub( "&amp;", "&")
	write_log('[info][gdrive] Downloading '..filename..' from '..format_number(os.getfilesize(filename)))
	write_log('[info][gdrive] Confirmed URL: '..direct_url)
	http.set_conf(http.OPT_REFERER, url)
	http.set_conf(http.OPT_TIMEOUT, MAXTIMEOUT)
	rc = 0
	n = 0
	repeat
		if rc ~= 0 then write_log('[error][gdrive.4] Retry '..n..': resume downloading '..filename..' from '..format_number(os.getfilesize(filename))) end
		rc, header = http.request{url = direct_url, output_filename = filename}
		for w in header:gmatch('[cC]ontent%-[tT]ype%: ([%w%/]+)') do
			ct = w
		end
		if rc == 33 then	-- Jika resume fresh download, maka request confirmed url (lagi) via simple GET method tanpa delete file yang telah ada
			write_log("[warning][gdrive] Invalid Response: Requested range was not delivered by the server")
			save_file(header,"gdrive_invalid_header.txt")
			rc, header, content = http.request(direct_url)
			links = http.collect_link(content, url)
			direct_url = nil
			for i, v in ipairs(links) do
				if string.find(v, "confirm=") then
					direct_url = v
				end
			end
			if direct_url == nil then
				save_file(content,"gdrive_invalid_content.htm")
				write_log("[error][gdrive.5] Can't find direct link to download. Invalid response from Google Drive")
				gist.update('2ff7b7c90cd7f219043bd450b5c1b05e', 'invalid.htm', content, 'Fail match: confirm=')
				return nil
			end
			direct_url = direct_url:gsub( "&amp;", "&")
			write_log('[info][gdrive] Re-updating confirmed url '..direct_url)
			rc = 33
		elseif ct == 'text/html' then	-- Jika download mulai dari 0, maka harus 2x confirmed url dan hapus downloaded file (yang berisi html)
			write_log("[warning][gdrive] Invalid Response when downloading")
			save_file(header,"gdrive_invalid_header.txt")
			if header:match('HTTP%/%d%.%d 416') or header:match('HTTP%/%d 416') then
				write_log('[warning][gdrive] Cancel downloading. File already fully downloaded.')
				return nil
			end
			direct_url = nil
			links = http.collect_link(load_file(filename), url)
			write_log('[info][gdrive] Deleting '..filename)
			os.remove(filename)
			for i, v in ipairs(links) do
				if string.find(v, "confirm=") then
					direct_url = v
				end
			end
			if direct_url == nil then
				save_file(content,"gdrive_invalid_content.htm")
				write_log("[error][gdrive.6] Can't find direct link to download. Invalid response from Google Drive")
				gist.update('2ff7b7c90cd7f219043bd450b5c1b05e', 'invalid.htm', content, 'Fail match: confirm=')
				return nil
			end
			direct_url = direct_url:gsub( "&amp;", "&")
			write_log('[info][gdrive] Re-updating confirmed url '..direct_url)
			rc = 33
		end
		n = n + 1
	until ((rc ~= 28) and (rc ~= 33)) -- until not time out (return code = 28) and not invalid response (return code = 33)
	if rc ~= 0 then
		write_log("[error][gdrive.7] "..http.error(rc)..". Downloaded: "..format_number(os.getfilesize(filename)).." bytes")
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
		or url:match('https://drive%.google%.com/././uc%?id=.-&export=download')
		or url:match('https://drive%.google%.com/uc%?export=download&id=.-')
end

function show_verified_gdrive()
	return 
[[
https://drive.google.com/uc?id=1kgzgnYfTnogMcXkrVIuaA8l3-RLkWB1K&export=download
https://drive.google.com/u/0/uc?id=1Y4EEsy6O9hdIawQVpxvv1PDM76q3k6qs&export=download
https://drive.google.com/file/d/0BxTdp26K4cYvSXE2SGxFY2VFLVk/view?usp=sharing
]]
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
-- instant test internal library
-- content = [[
-- https://drive.google.com/uc?id=1i_sZd6plHz8sJGYAwPhBslN70EN1cAPZ&export=download
-- ]]

-- local MAXTRY = 10
-- for url in content:gmatch("[^\r\n]+") do
	-- if verify_gdrive(url) then
		-- done = download_gdrive(url)
		-- try = 1
		-- while ((try <= MAXTRY) and (done == false)) do
			-- print('Retry '..try)
			-- done = download_gdrive(url)
			-- try = try + 1
		-- end
	-- else
		-- print('URL not valid for Google Drive')
	-- end
-- end

-------------------------------------------------------------------------------
--	Library Interface
-------------------------------------------------------------------------------
return {
	download = download_gdrive,
	verified = show_verified_gdrive,
	verify = verify_gdrive
}

