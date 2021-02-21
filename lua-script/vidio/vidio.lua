-- Lua Library : Download file from vidio.com
-- Format Input URL = 
--		https://www.vidio.com/watch/1994460-god-of-gamblers-part-3-back-to-shanghai
-- Interpreter : modified lua https://drive.google.com/file/d/1imqMbflxEEc8OsTCJoHiuMufdAfJTNSg/view?usp=drivesdk
-- 5:44 20 August 2020, Rawamangun

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
function download_vidio(url, callback_function_write_log, callback_function_on_success)
	local rc, content, id, title, url1, prevline
	local write_log
 
	if callback_function_write_log ~= nil then
		write_log = callback_function_write_log
	else
		write_log = my_write_log
	end
		
	id, title = url:match('https://www.vidio.com/watch/(%d+)%-(%S+)')
	if id == nil then
		write_log("[error][vidio.download] Can't find ID. Invalid URL")
		return nil
	end
	http.set_conf(http.OPT_COOKIEFILE, "vidio_cookies.txt")
	
	--download vidio: step 1
	url1 = "https://www.vidio.com/interactions_stream.json?video_id="..id.."&type=videos"
	rc, content = http.get_url(url1)
	if rc ~= 0 then
		write_log("[error][vidio.download] "..http.error(rc))
		return false
	end
	url1 = string.match(content, '{"source":"(.-)"')
	if url1 == nil then
		save_file(content, 'vidio.json')
		write_log("[error][vidio.download] Can't find vidio download link. Invalid response. Check vidio.json")
		return nil
	end
	--download vidio: step 2
	rc,content = http.get_url(url1)
	if rc ~= 0 then
		write_log("[error][vidio.download] "..http.error(rc))
		return false
	end
	url1 = ""
	for line in content:gmatch("[^\r\n]+") do
		prevline = url1
		url1 = line
	end
	codecs, resolution = string.match(prevline, 'CODECS="(%S-)",RESOLUTION=(%S-),')
	if codecs == nil then codecs = "none" end
	if resolution == nil then resolution = "none" end
	--download vidio: step 3
	if DEBUG then
		rc = os.execute('youtube-dl.exe --cookies vidio_cookies.txt --no-progress --restrict-filenames --hls-prefer-native --output '..title..'.mp4 '..url1..' >> '..LOG_FILE)
	else
		rc = os.execute('youtube-dl.exe --cookies vidio_cookies.txt --restrict-filenames --hls-prefer-native --output '..title..'.mp4 '..url1)
	end
	
	if rc ~= 0 then
		write_log("[error][vidio.download] Failed")
		return false
	end
	
	--download subtitle: step 1
	rc, content = http.get_url(url)
	if rc ~= 0 then
		write_log("[error][vidio.download] "..http.error(rc))
		return false
	end
	url1 = string.match(content, '(https://token(%S-)vtt)')
	if url1 == nil then
		write_log("[warning][vidio.download] Can't find subtitle download link")
	else
		local fi
		--download subtitle: step 2
		rc = http.get_url(url1, title..'.vtt')
		if rc ~= 0 then
			write_log("[error][vidio.download] "..http.error(rc))
			return false
		end
		fi = io.open(title..'.vtt', "r")
		if fi == nil then
			write_log("[error][vidio.download] Load file "..title..'.vtt')
			return nil
		end
		fi:seek("set",8)	--skip unneeded header WEBVTT
		content = fi:read("*a")
		fi:close()
		save_file(content, title..'.srt')
		os.remove(title..'.vtt')
		write_log("[info][vidio.download] Success download subtitle "..title..'.srt')
	end

	if callback_function_on_success ~= nil then callback_function_on_success(string.format("%s %s; %s (%s %s)", os.date(), url, title..'.mp4', codecs, resolution)) end
	write_log(string.format("[info][vidio.download] Success saving file %s (%s %s)", title..'.mp4', codecs, resolution))
	return true
end

function verify_vidio(url)
	return url:match('https://www.vidio.com/watch/%d+%-%S+')
end

return {
	download = download_vidio,
	verify = verify_vidio
}
