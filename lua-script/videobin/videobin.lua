-- Lua 5.1.5.XL Script for downloading media from https://videobin.com
-- Interpreter : luaX https://github.com/dhaninovan/luax/releases/download/v5.1.5.77/lua.exe

dofile('../strict.lua')
dofile('../common.lua')

-- Output :
--	true : on success
--	false : timeout
--	nil : invalid response and other fail status
function download_videobin(url, callback_function_write_log, callback_function_on_success)
	local rc, headers, content, title, filename
	local write_log, media_url
	
	if callback_function_write_log ~= nil then
		write_log = callback_function_write_log
	else
		write_log = my_write_log
	end
	
	write_log('[info][videobin] Process '..url)
	rc, headers, content = http.request(url)
	if rc ~= 0 then
		write_log("[error][videobin] "..http.error(rc))
		return false
	end
	
	-- Do processing in here
	media_url = string.match(content, '","(.-)"],')
	filename = string.match(content, '22px%;"%> (.-)\n')
	if media_url == nil then write_log("[error][videobin] Invalid response. Can't find media URL. (1)") save_file(content, 'videobin_invalid_content.htm') return nil end
	if filename == nil then write_log("[error][videobin] Invalid response. Can't find string for filename. (2)") save_file(content, 'videobin_invalid_content.htm') return nil end	
	filename = filename:gsub('%W','%_')..'.mp4'
	
	rc, headers = http.request{url = media_url, output_filename = filename}
	if rc ~= 0 then
		write_log("[error][videobin] "..http.error(rc))
		return false
	end
	
	if callback_function_on_success ~= nil then
		callback_function_on_success(string.format("%s %s; %s (%s bytes)", os.date(), url, filename, format_number(os.getfilesize(filename))))
	end
	write_log(string.format("[info][videobin] Success saving file '%s' (%s bytes)", filename, format_number(os.getfilesize(filename))))
	return true
end

function verify_videobin(url)
	return url:match('https://videobin%.co/%w') or url:match('http://videobin%.co/%w')
end

function show_verified_videobin()
	return 
[[
https://videobin.co/gr1rosppf8x6
]]
end

-------------------------------------------------------------------------------
--	Library Testing
-------------------------------------------------------------------------------
-- content = [[
-- https://videobin.co/gr1rosppf8x6
-- ]]

-- for url in content:gmatch("[^\r\n]+") do
	-- if verify_videobin(url) then
		-- download_videobin(url)
	-- else
		-- my_write_log('[error][videobin] invalid URL')
	-- end
-- end

-------------------------------------------------------------------------------
--	Library Interface
-------------------------------------------------------------------------------
return {
	download = download_videobin,
	verified = show_verified_videobin,
	verify = verify_videobin
}

-- https://c1.videobin.co/oudvgno4mjtk2yixv7r6cazvd4bippxjitldxqc2rg6qwdib2rkdggw7mf4q/v.mp4
-- https://c1.videobin.co/hls/oudvgno4mjtk2yixv7r6cazvd4bippxjitldxqc2rg6qwdib2rkdggw7mf4q/.urlset/master.m3u8
-- https://c1.videobin.co/hls/oudvgno4mjtk2yixv7r6cazvd4bippxjitldxqc2rg6qwdib2rkdggw7mf4q/.urlset/index-v1-a1.m3u8
-- https://c1.videobin.co/hls/oudvgno4mjtk2yixv7r6cazvd4bippxjitldxqc2rg6qwdib2rkdggw7mf4q/.urlset/iframes-v1-a1.m3u8

-- Video Source : 
-- https://piesitosypantaletitas.net/viewforum.php?f=30
-- https://piesitosypantaletitas.net/viewtopic.php?f=30&t=14190
