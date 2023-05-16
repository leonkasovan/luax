-- Multi download url : gdrive, solidfiles, general
-- Interpreter : lua with Xtra Library : http, csv, json, iup
-- Download interpreter https://github.com/dhaninovan/luax/releases/download/v5.1.5.77/lua.exe
-- 16:55 28 June 2020 (c) dhani.novan@gmail.com

-- GLOBAL SETTING
local MAXTRY = 5
local TEMP_FILE = "file.tmp"
local MAXTIMEOUT = 9999	-- set max timeout

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
	if callback_function_on_success ~= nil then
		callback_function_on_success(string.format("%s %s; %s (%s bytes)", os.date(), url, filename, format_number(os.getfilesize(filename))))
	end
	write_log(string.format("[info][general] Success saving file '%s' (%s bytes)", filename, format_number(os.getfilesize(filename))))
	return true
end

--- Import Library
local pastebin = dofile('../pastebin/pastebin.lua')
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

SUCCESS_LOG_TITLE = 'success_log'
function update_success_log(data)
	pastebin.append_by_title(data, SUCCESS_LOG_TITLE)
end

function verify(url)
	local success_log = pastebin.read_by_title(SUCCESS_LOG_TITLE)
	
	if success_log == nil then success_log = "" end
	if url:match("^https://eropics%.to$") then success_log = "" end	-- ignore spesific url
	if url:match("^https://imagesbase%.ru$") then success_log = "" end	-- ignore spesific url
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
	else
		write_log("[warning][verify] Skipping existing URL "..url)
		return nil
	end
end

-- Check lua instance
if os.info() == "Windows" then
	-- to be defined
else
	local fi, res
	local n_instance = 0
	fi = io.popen('ps -x | grep luax')
	if fi then
		res = fi:read("*a")
		fi:close()
		for hh,mm in res:gmatch('(%d+)%:(%d+) luax multi%_host%_downloader%.lua') do
			n_instance = n_instance + 1
		end
		if n_instance > 1 then
			write_log("[warning] There is another multi_host_downloader.lua script instance. Exiting")
			return 0
		end
	end
end

-- Get list of url
LIST_URLS_TITLE = 'list_urls'
local urls = pastebin.read_by_title(LIST_URLS_TITLE)
local try

try = 1
while ((urls == nil) and (try < MAXTRY)) do
	urls = pastebin.read_by_title(LIST_URLS_TITLE)
	try = try + 1
end
if urls == nil then
	write_log('Fail to grab list of url after '..try..' times trying.')
	return -1
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
				done = download_library(url, write_log, update_success_log)
				try = 1
				while ((try <= MAXTRY) and (done == false)) do
					write_log('Retry '..try)
					done = download_library(url, write_log, update_success_log)
					try = try + 1
				end
				collectgarbage("collect")
			end
			nurl = nurl + 1
		end
	end
end
return 0
--if not DEBUG then os.execute("pause") end
