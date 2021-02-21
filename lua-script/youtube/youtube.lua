-- Lua Library : Download media file from youtube.com
-- Format Input URL = 
--		https://www.youtube.com/watch?v=GAyvgz8_zV8
-- Interpreter : modified lua https://drive.google.com/file/d/1imqMbflxEEc8OsTCJoHiuMufdAfJTNSg/view?usp=drivesdk
-- 4:39 24 August 2020, Rawamangun

-- GLOBAL SETTING
local MAXTIMEOUT = 900	-- set max timeout 15 minutes
local LOG_FILE = "youtube-dl.log"
--local DEBUG = true	-- write all log to a file (LOG_FILE)
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
function download_youtube(url, callback_function_write_log, callback_function_on_success)
	local rc, content, id, title, url1, prevline
	local write_log
 
	if callback_function_write_log ~= nil then
		write_log = callback_function_write_log
	else
		write_log = my_write_log
	end
		
	http.set_conf(http.OPT_COOKIEFILE, "youtube_cookies.txt")
	if DEBUG then
		rc = os.execute('youtube-dl.exe --write-sub --sub-lang id,en --cookies youtube_cookies.txt --no-progress --restrict-filenames -o "%(uploader)s - %(title)s.%(ext)s" '..url..' >> '..LOG_FILE)
	else
		rc = os.execute('youtube-dl.exe --write-sub --sub-lang id,en --cookies youtube_cookies.txt --restrict-filenames -o "%(uploader)s - %(title)s.%(ext)s" '..url)
	end
	
	if rc ~= 0 then
		write_log("[error][youtube.download] Failed")
		return false
	end
	
	if callback_function_on_success ~= nil then callback_function_on_success(string.format("%s %s", os.date(), url)) end
	write_log(string.format("[info][youtube.download] Success saving file from url %s", url))
	return true
end

-- Output :
--	true : on success
--	false : fail, timeout or network problem (can be retried)
--	nil : fail, invalid response
function download_raw_youtube(url, callback_function_write_log, callback_function_on_success)
	local rc, content, id, title, url1, prevline
	local write_log
 
	if callback_function_write_log ~= nil then
		write_log = callback_function_write_log
	else
		write_log = my_write_log
	end
		
	http.set_conf(http.OPT_COOKIEFILE, "youtube_cookies.txt")
	if DEBUG then
		rc = os.execute('youtube-dl.exe -k --write-sub --sub-lang id,en --cookies youtube_cookies.txt --no-progress --restrict-filenames -o "%(uploader)s - %(title)s.%(ext)s" '..url..' >> '..LOG_FILE)
	else
		rc = os.execute('youtube-dl.exe -k --write-sub --sub-lang id,en --cookies youtube_cookies.txt --restrict-filenames -o "%(uploader)s - %(title)s.%(ext)s" '..url)
	end
	
	if rc ~= 0 then
		write_log("[error][youtube.download] Failed")
		return false
	end
	
	if callback_function_on_success ~= nil then callback_function_on_success(string.format("%s %s", os.date(), url)) end
	write_log(string.format("[info][youtube.download] Success saving file from url %s", url))
	return true
end

-- Output :
--	true : on success
--	false : fail, timeout or network problem (can be retried)
--	nil : fail, invalid response
function download_audio_youtube(url, callback_function_write_log, callback_function_on_success)
	local rc, content, id, title, url1, prevline
	local write_log
 
	if callback_function_write_log ~= nil then
		write_log = callback_function_write_log
	else
		write_log = my_write_log
	end
		
	http.set_conf(http.OPT_COOKIEFILE, "youtube_cookies.txt")
	if DEBUG then
		rc = os.execute('youtube-dl.exe --add-metadata --cookies youtube_cookies.txt --restrict-filenames -x --audio-format mp3 -o "%(artist)s - %(title)s.%(ext)s" '..url..' >> '..LOG_FILE)
	else
		rc = os.execute('youtube-dl.exe --add-metadata --cookies youtube_cookies.txt --restrict-filenames -x --audio-format mp3 -o "%(artist)s - %(title)s.%(ext)s" '..url)
	end
	
	if rc ~= 0 then
		write_log("[error][youtube.download] Failed")
		return false
	end
	
	if callback_function_on_success ~= nil then callback_function_on_success(string.format("%s %s", os.date(), url)) end
	write_log(string.format("[info][youtube.download] Success saving file from url %s", url))
	return true
end

function verify_youtube(url)
	return url:match('https://www%.youtube%.com/watch%?v=%S+') or url:match('https://music%.youtube%.com/watch%?v=%S+')
end

return {
	download = download_youtube,
	download_raw = download_raw_youtube,
	download_audio = download_audio_youtube,
	verify = verify_youtube
}
