-- Lua Library : Download file from letsupload.io
-- Format Input URL = 
--		https://letsupload.io/%w+
--		https://letsupload.io/n1lH
-- Interpreter : modified lua https://drive.google.com/file/d/1imqMbflxEEc8OsTCJoHiuMufdAfJTNSg/view?usp=drivesdk
-- 5:22 06 August 2020, Rawamangun

-- GLOBAL SETTING
local MAXTIMEOUT = 900	-- set max timeout 15 minutes
local LOG_FILE = "letsupload.log"
local DEBUG = true	-- write all log to a file (LOG_FILE)
--local DEBUG = false	-- write all log to console output

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

-- Output :
--	true : on success
--	false : fail, timeout or network problem (can be retried)
--	nil : fail, invalid response
function download_letsupload(url, callback_function_write_log, callback_function_on_success)
	local rc, content, filename, filesize, direct_url, id
	local write_log
 
	if callback_function_write_log ~= nil then
		write_log = callback_function_write_log
	else
		write_log = my_write_log
	end
	
	rc, content = http.get_url(url)
	if rc ~= 0 then
		write_log("[error][letsupload.download] "..http.error(rc))
		return false
	end
	os.execute("timeout 4")
	
	id = url:match('https://letsupload.io/(%w+)')
	if id == nil then
		write_log("[error][letsupload.download] Can't find ID. Invalid URL")
		return nil
	end
	
	filename = string.match(content, '<title>(.-) %- LetsUpload')
	filesize = string.match(content, '</i> size : <p>(.-)</p></span></li>')
	if filename == nil or filesize == nil then
		write_log("[error][letsupload.download] Can't find filename / filesize. Invalid response from letsupload.io")
		save_file(content,"letsupload_invalid_content.htm")
		return nil
	end
	
	url = string.match(content, "href='(.-)'>download now")
	if url == nil then
		write_log("[error][letsupload.download] Can't find download link. Invalid response from letsupload.io")
		save_file(content,"letsupload_invalid_content.htm")
		return nil
	end
	http.set_conf(http.OPT_TIMEOUT, MAXTIMEOUT)
	rc, content = http.get_url(url)
	if rc ~= 0 then
		write_log("[error][letsupload.download] "..http.error(rc))
		return false
	end
	
	direct_url = string.match(content, 'content="0;url=(.-)"')
	if direct_url == nil then
		write_log("[error][letsupload.download] Can't find direct link. Invalid response from letsupload.io")
		save_file(content,"letsupload_invalid_content.htm")
		return nil
	end
	http.set_conf(http.OPT_TIMEOUT, MAXTIMEOUT)
	rc = http.get_url(direct_url, filename)
	if rc ~= 0 then
		write_log("[error][letsupload.download] "..http.error(rc))
		return false
	end
	
	-- Update success list of URL
	os.remove('http_header.txt')
	if callback_function_on_success ~= nil then callback_function_on_success(string.format("%s %s; %s (%s)", os.date(), url, filename, filesize)) end
	write_log(string.format("[info][letsupload.download] Success saving file %s (%s)", filename, filesize))
	return true
end

function verify_letsupload(url)
	return url:match('^https://letsupload.io/%w+')
end

return {
	download = download_letsupload,
	verify = verify_letsupload
}
