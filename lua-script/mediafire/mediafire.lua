-- Lua 5.1.5.XL Script for downloading media from https://mediafire.com
-- Interpreter : luaX https://github.com/dhaninovan/luax/releases/download/v5.1.5.77/lua.exe

dofile('../strict.lua')
dofile('../common.lua')

function my_write_log(data)
	print(os.date("%d/%m/%Y %H:%M:%S ")..data)
end

-- Output :
--	true : on success
--	false : timeout
--	nil : invalid response and other fail status
function download_mediafire(url, callback_function_write_log, callback_function_on_success)
	local rc, headers, content, title, filename
	local write_log, media_url
	
	if callback_function_write_log ~= nil then
		write_log = callback_function_write_log
	else
		write_log = my_write_log
	end
	
	write_log('[info][mediafire] Process '..url)
	rc, headers, content = http.request(url)
	if rc ~= 0 then
		write_log("[error][mediafire] "..http.error(rc))
		return false
	end
	
	-- Do processing in here
	media_url = string.match(content, 'label="Download file"%s+href="(.-)"')
	if media_url == nil then write_log('[error][mediafire] invalid response. (1)') save_file(content, 'pixeldrain_invalid_content.htm') return nil end
	filename = string.match(content, '<div class="filename">(.-)</div>')
	if filename == nil then write_log('[error][mediafire] invalid response. (2)') save_file(content, 'pixeldrain_invalid_content.htm') return nil end
	
	http.set_conf(http.OPT_TIMEOUT, 1800)
	http.set_conf(http.OPT_REFERER, url)
	rc, headers = http.request{url = media_url, output_filename = filename}
	if rc ~= 0 then
		write_log("[error][mediafire] "..http.error(rc))
		return false
	end
	
	if callback_function_on_success ~= nil then
		callback_function_on_success(string.format("%s %s; %s (%s bytes)", os.date(), url, filename, format_number(os.getfilesize(filename))))
	end
	write_log(string.format("[info][mediafire] Success saving file '%s' (%s bytes)", filename, format_number(os.getfilesize(filename))))
	return true
end

function verify_mediafire(url)
	return url:match('https?://www.mediafire.com/file/%S+/.-/file')
end

function show_verified_mediafire()
	return 
[[
http://www.mediafire.com/file/g75g6riihwawxb1/profile.dat/file
]]
end

-------------------------------------------------------------------------------
--	Library Testing
-------------------------------------------------------------------------------
-- content = [[
-- http://www.mediafire.com/file/g75g6riihwawxb1/profile.dat/file
-- http://www.mediafire.com/file/j9kmifwtxxs/giaoantoan7.rar/file
-- ]]

-- for url in content:gmatch("[^\r\n]+") do
	-- if verify_mediafire(url) then
		-- download_mediafire(url)
	-- else
		-- my_write_log('[error][mediafire] invalid URL')
	-- end
-- end


-------------------------------------------------------------------------------
--	Library Interface
-------------------------------------------------------------------------------
return {
	download = download_mediafire,
	verified = show_verified_mediafire,
	verify = verify_mediafire
}
