-- Lua Library : Download media file from youtube.com
-- Format Input URL = 
--		https://www.youtube.com/watch?v=GAyvgz8_zV8
-- Interpreter : modified lua https://drive.google.com/file/d/1imqMbflxEEc8OsTCJoHiuMufdAfJTNSg/view?usp=drivesdk
-- 4:39 24 August 2020, Rawamangun

require('strict')
require('common')

-- GLOBAL SETTING
local MAXTIMEOUT = 900	-- set max timeout 15 minutes
local LOG_FILE = "youtube-dl.log"
local YOUTUBE_DL = ""

if os.info() == "Windows" then
	YOUTUBE_DL = "youtube-dl.exe"
else
	YOUTUBE_DL = "/usr/share/bin/youtube-dl"
end

http.set_conf(http.OPT_USERAGENT, 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.181 Mobile Safari/537.36')

-- Output :
--	true : on success
--	false : fail, timeout or network problem (can be retried)
--	nil : fail, invalid response
function download_youtube(url, callback_function_write_log, callback_function_on_success)
	local rc, content, title, headers, write_log
 
	if callback_function_write_log ~= nil then
		write_log = callback_function_write_log
	else
		write_log = my_write_log
	end
	
	rc, headers, content = http.request(url)
	if rc ~= 0 then
		write_log("[error][youtube] "..http.error(rc), rc)
		return false
	end
	title = string.match(content, 'title":"(.-)",')
	if title == nil then write_log('[error][youtube] Cant find title. Check youtube_invalid_content.htm') save_file(content, 'youtube_invalid_content.htm') return nil end
	
	http.set_conf(http.OPT_COOKIEFILE, "youtube_cookies.txt")
	rc = os.execute(YOUTUBE_DL..' --write-sub --sub-lang id,en --cookies youtube_cookies.txt --no-progress --restrict-filenames -o "%(uploader)s - %(title)s.%(ext)s" '..url..' >> '..LOG_FILE)
	if rc ~= 0 then
		write_log("[error][youtube.download] Failed")
		return false
	end
	
	if callback_function_on_success ~= nil then callback_function_on_success(string.format("%s %s Title: %s", os.date(), url, title)) end
	write_log(string.format("[info][youtube.download] Success saving file from url %s Title: %s", url, title))
	return true
end

-- Output :
--	true : on success
--	false : fail, timeout or network problem (can be retried)
--	nil : fail, invalid response
function download_raw_youtube(url, callback_function_write_log, callback_function_on_success)
	local rc, content, title, headers, write_log
 
	if callback_function_write_log ~= nil then
		write_log = callback_function_write_log
	else
		write_log = my_write_log
	end
	
	rc, headers, content = http.request(url)
	if rc ~= 0 then
		write_log("[error][youtube] "..http.error(rc), rc)
		return false
	end
	title = string.match(content, 'title":"(.-)",')
	if title == nil then write_log('[error][youtube] Cant find title. Check youtube_invalid_content.htm') save_file(content, 'youtube_invalid_content.htm') return nil end
	
	http.set_conf(http.OPT_COOKIEFILE, "youtube_cookies.txt")
	rc = os.execute(YOUTUBE_DL..' -k --write-sub --sub-lang id,en --cookies youtube_cookies.txt --no-progress --restrict-filenames -o "%(uploader)s - %(title)s.%(ext)s" '..url..' >> '..LOG_FILE)
	if rc ~= 0 then
		write_log("[error][youtube.download] Failed")
		return false
	end
	
	if callback_function_on_success ~= nil then callback_function_on_success(string.format("%s %s Title: %s", os.date(), url, title)) end
	write_log(string.format("[info][youtube.download] Success saving file from url %s Title: %s", url, title))
	return true
end

-- Output :
--	true : on success
--	false : fail, timeout or network problem (can be retried)
--	nil : fail, invalid response
function download_audio_youtube(url, callback_function_write_log, callback_function_on_success)
	local rc, content, title, headers, write_log
 
	if callback_function_write_log ~= nil then
		write_log = callback_function_write_log
	else
		write_log = my_write_log
	end
	
	url = url:gsub('&(.-)$','')	-- remove any additional parameter
	rc, headers, content = http.request(url:gsub('music','www'))	-- grab title in www.youtube.com
	if rc ~= 0 then
		write_log("[error][youtube] "..http.error(rc), rc)
		return false
	end
	title = string.match(content, 'title":"(.-)",')
	if title == nil then write_log('[error][youtube] Cant find title. Check youtube_invalid_content.htm') save_file(content, 'youtube_invalid_content.htm') return nil end
	-- title = title:gsub("[^%.%w%s%-%_%(%)%[%]]","")

	http.set_conf(http.OPT_COOKIEFILE, "youtube_cookies.txt")
	rc = os.execute(YOUTUBE_DL..' --add-metadata --cookies youtube_cookies.txt --restrict-filenames -x --audio-format mp3 -o "%(artist)s - %(title)s.%(ext)s" '..url..' >> '..LOG_FILE)
	if rc ~= 0 then
		write_log("[error][youtube.download] Failed")
		return false
	end
	
	if callback_function_on_success ~= nil then callback_function_on_success(string.format("%s %s Title: %s", os.date(), url, title)) end
	write_log(string.format("[info][youtube.download] Success saving file from url %s Title: %s", url, title))
	return true
end

function verify_youtube(url)
	return url:match('https://www%.youtube%.com/watch%?v=%S+')
end

function verify_youtube_music(url)
	return url:match('https://music%.youtube%.com/watch%?v=%S+')
end

function show_verified_youtube()
	return 
[[
https://www.youtube.com/watch?v=Jw1-6p7W9eA
https://music.youtube.com/watch?v=VTq0QNryLt4
]]
end

return {
	download = download_youtube,
	download_raw = download_raw_youtube,
	download_audio = download_audio_youtube,
	verified = show_verified_youtube,
	verify_music = verify_youtube_music,
	verify = verify_youtube
}
