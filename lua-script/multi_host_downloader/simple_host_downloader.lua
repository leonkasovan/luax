-- Simple download url : gdrive, solidfiles, general
-- Interpreter : lua with Xtra Library : http, csv, json, iup
-- Download interpreter https://github.com/dhaninovan/luax/releases/download/v5.1.5.77/lua.exe
-- 16:55 28 June 2020 (c) dhani.novan@gmail.com

-- GLOBAL SETTING
local MAXTRY = 10
local TEMP_FILE = "file.tmp"
local MAXTIMEOUT = 3600	-- set max timeout 30 minutes

-- Get list of url: change here
local urls = [[
https://github.com/PortsMaster/PortMaster-Releases/releases/latest/download/mono-6.12.0.122-aarch64.squashfs
]]

function write_log(data)
	print(os.date("%d/%m/%Y %H:%M:%S ")..data)
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
		write_log(string.format("[info][general_download] Success and renamed with filename: %s (%s bytes)", server_filename, server_filesize))
		return true
	end
	if callback_function_on_success ~= nil then callback_function_on_success(string.format("%s %s; %s", os.date(), url, filename)) end
	write_log("[info][general_download] Success and saved with filename: "..filename)
	return true
end

--- Import Library
local gist = dofile('../github/gist.lua')
local gdrive = dofile('../gdrive/gdrive2.lua')
local solidfiles = dofile('../solidfiles/solidfiles.lua')
local racaty = dofile('../racaty/racaty.lua')
local letsupload = dofile('../letsupload/letsupload.lua')
local vidio = dofile('../vidio/vidio.lua')
local youtube = dofile('../youtube/youtube.lua')
local filedot = dofile('../filedot/filedot.lua')
local cyberdrop = dofile('../cyberdrop/cyberdrop.lua')
local videobin = dofile('../videobin/videobin.lua')
local pixeldrain = dofile('../pixeldrain/pixeldrain.lua')
local mediafire = dofile('../mediafire/mediafire.lua')
local imx = dofile('../imx/imx.lua')
local games_db = dofile('../games-database/games_db.lua')
local girlygirlpic = dofile('../girlygirlpic/girlygirlpic.lua')
local eropics = dofile('../eropics/eropics.lua')
local imagesbase = dofile('../imagesbase/imagesbase.lua')
local vimm = dofile('../vimm/vimm.lua')
local nopaystation = dofile('../nopaystation/nopaystation.lua')

function verify(url)
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
		elseif cyberdrop.verify(url) then
			return cyberdrop.download
		elseif videobin.verify(url) then
			return videobin.download
		elseif pixeldrain.verify(url) then
			return pixeldrain.download
		elseif pixeldrain.verify_list(url) then
			return pixeldrain.download_list
		elseif mediafire.verify(url) then
			return mediafire.download
		elseif imx.verify(url) then
			return imx.download
		elseif games_db.verify(url) then
			return games_db.download
		elseif girlygirlpic.verify(url) then
			return girlygirlpic.download
		elseif girlygirlpic.verify_agency(url) then
			return girlygirlpic.download_agency
		elseif girlygirlpic.verify_tag(url) then
			return girlygirlpic.download_tag
		elseif girlygirlpic.verify_model(url) then
			return girlygirlpic.download_model
		elseif girlygirlpic.verify_country(url) then
			return girlygirlpic.download_country
		elseif eropics.verify(url) then
			return eropics.download
		elseif eropics.verify_category(url) then
			return eropics.download_category
		elseif imagesbase.verify(url) then
			return imagesbase.download
		elseif imagesbase.verify_category(url) then
			return imagesbase.download_category
		elseif vimm.verify(url) then
			return vimm.download
		elseif nopaystation.verify(url) then
			return nopaystation.download
		elseif url:match('^https?://.-/.+$') then
			return general_download
		elseif url:match('^ftps?://.-/.+$') then
			return general_download
		else
			write_log("[error][verify] Downloader is not defined for "..url)
			return nil
		end
end

if #arg == 1 then
	if os.info() == "Windows" then
		http.set_conf(http.OPT_PROGRESS_TYPE, 3)
	end
	http.set_conf(http.OPT_NOPROGRESS, false)
end

-- Download url(s)
local nurl, url, done, download_library
nurl = 1
for url in urls:gmatch("[^\r\n]+") do
	if #url ~= 0 then	-- url is not empty string
		if url:byte(1) ~= 35 then	-- skip char #
			write_log("---------------------------------------------------------------------------")
			write_log("Processing URL "..nurl..": "..url)
			download_library = verify(url)
			if download_library ~= nil then
				done = download_library(url, write_log, write_log)
				try = 1
				while ((try <= MAXTRY) and (done == false)) do
					write_log('Retry '..try)
					done = download_library(url, write_log, write_log)
					try = try + 1
				end
				collectgarbage("collect")
			end
			nurl = nurl + 1
		end
	end
end
return 0

