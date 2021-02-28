-- Multi download url : gdrive, solidfiles, general
-- Interpreter : lua with Xtra Library : http, csv, json, iup
-- Download interpreter https://drive.google.com/file/d/1imqMbflxEEc8OsTCJoHiuMufdAfJTNSg/view?usp=sharing
-- 16:55 28 June 2020 (c) dhani.novan@gmail.com

-- GLOBAL SETTING
local MAXTRY = 10
local TEMP_FILE = "file.tmp"
local MAXTIMEOUT = 1800	-- set max timeout 30 minutes
local LOG_FILE = "multi_host_downloader.log"
local DEBUG = true	-- write all log to a file (LOG_FILE)
-- local DEBUG = false	-- write all log to console output

function write_log(data)
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

function general_download(url, callback_function_write_log, callback_function_on_success)
	local rc, filename, server_filesize, server_filename, header
	local write_log
	
	if callback_function_write_log ~= nil then
		write_log = callback_function_write_log
	else
		write_log = _G.write_log
	end
	
	filename = http.resource_name(url)
	if filename == nil or #filename == 0 then
		filename = TEMP_FILE
	end
	http.set_conf(http.OPT_TIMEOUT, MAXTIMEOUT)
	rc, header = http.request{url = url, output_filename = filename}
	if rc ~= 0 then
		print("Error: "..http.error(rc), rc)
		return false
	end
	if rc ~= 0 then
		write_log("[error][general_download] "..http.error(rc))
		return false
	end
	
	server_filename = string.match(header, '[Ff]ilename%s*=%s*"(.-)"')
	server_filesize = string.match(header, '[Cc]ontent%-[Ll]ength%s*:%s*(%d+)')
	if server_filename ~= nil and server_filesize ~= nil then
		server_filename = server_filename:gsub('[%/%\%:%?%*%"%<%>%|]', "")
		os.rename(filename, server_filename)
		if callback_function_on_success ~= nil then callback_function_on_success(string.format("%s %s; %s (%s)", os.date(), url, server_filename, server_filesize)) end
		write_log(string.format("[info][general_download] Success and renamed with filename: %s (%s bytes)"), server_filename, server_filesize)
		return true
	end
	if callback_function_on_success ~= nil then callback_function_on_success(string.format("%s %s; %s", os.date(), url, filename)) end
	write_log("[info][general_download] Success and saved with filename: "..filename)
	return true
end

--- Import Library
--local gist = import_library('https://gist.github.com/dhaninovan/c99bf60b414d902a447b90633c8dd9d4/raw/')
--local gdrive = import_library('https://gist.github.com/dhaninovan/d94d938e96b3171a42e47aa1f8c0c22b/raw/')
--local solidfiles = import_library('https://gist.github.com/dhaninovan/44a8586f3ec91ad479a690ecfdb608a7/raw/')
--local racaty = import_library('https://gist.github.com/dhaninovan/d883c5513627c5b8ae4711b5ecf87486/raw/')
--local letsupload = import_library('https://gist.github.com/dhaninovan/311d56a792c6b98cb277cb6bca47396b/raw/')
--local vidio = import_library('https://gist.github.com/dhaninovan/f5dcfa5f411b026f5bcaa646a922514f/raw/')
--local youtube = import_library('https://gist.github.com/dhaninovan/5d858219718de619428a3ebb2f6f34d9/raw/')


local gist = dofile('../github/gist.lua')
local gdrive = dofile('../gdrive/gdrive.lua')
local solidfiles = dofile('../solidfiles/solidfiles.lua')
local racaty = dofile('../racaty/racaty.lua')
local letsupload = dofile('../letsupload/letsupload.lua')
local vidio = dofile('../vidio/vidio.lua')
local youtube = dofile('../youtube/youtube.lua')
local filedot = dofile('../filedot/filedot.lua')


function update_success_log(data)
	local success_log = gist.read('https://gist.github.com/dhaninovan/19611e27b450185cd15241035b5b2110')
	
	if success_log == nil then success_log = "" end
	gist.update('19611e27b450185cd15241035b5b2110', 'success.log', string.format("%s\n%s", success_log, data))
end

function verify(url)
	local success_log = gist.read('https://gist.github.com/dhaninovan/19611e27b450185cd15241035b5b2110')
	
	if success_log == nil then success_log = "" end
	if success_log:find(url, 1, true) == nil then
		if gdrive.verify(url) then
			return gdrive.download
		elseif solidfiles.verify(url) then
			return solidfiles.download
		elseif racaty.verify(url) then
			return racaty.download
		elseif letsupload.verify(url) then
			return letsupload.download
		elseif vidio.verify(url) then
			return vidio.download
		elseif youtube.verify(url) then
			return youtube.download
		elseif youtube.verify_music(url) then
			return youtube.download_audio
		elseif filedot.verify(url) then
			return filedot.download
		elseif url:match('^https?://.-/.+$') then
			return general_download
		else
			write_log("[error][verify] Downloader is not defined for "..url)
			return nil
		end
	else
		write_log("[warning][verify] Skipping existing URL "..url)
		return nil
	end
end

-- Get list of url
-- local urls = gist.read('https://gist.github.com/dhaninovan/5d47a78e821dca8d37d990f267c6e209')
-- if urls == nil then
	-- return -1
-- end

urls = [[
https://www.youtube.com/watch?v=P4Oc-RmXbL0
]]

-- Download url(s)
local nurl, url, try, done, download_library
nurl = 1
for url in urls:gmatch("[^\r\n]+") do
	if #url ~= 0 then	-- url is not empty string
		write_log("---------------------------------------------------------------------------")
		write_log("Processing URL "..nurl..": "..url)
		download_library = verify(url)
		if download_library ~= nil then
			done = download_library(url, write_log, update_success_log)
			try = 1
			while ((try <= MAXTRY) and (done == false)) do
				write_log('Retry '..try)
				done = download_library(url, write_log, update_success_log)
				try = try + 1
			end
		end
		nurl = nurl + 1
	end
end
return 0
--if not DEBUG then os.execute("pause") end
