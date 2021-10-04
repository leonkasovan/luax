-- Lua 5.1.5.XL Script for downloading media from https://pixhost.to
-- Interpreter : luaX https://github.com/dhaninovan/luax/releases/download/v5.1.5.77/lua.exe
-- dhani.novan@gmail.com 31/12/2021, Rawamangun

dofile('../strict.lua')
dofile('../common.lua')

function my_write_log(data)
	print(os.date("%d/%m/%Y %H:%M:%S ")..data)
end

-- Output :
--	true : on success
--	false : timeout
--	nil : invalid response and other fail status
function download_pixhost(url, callback_function_write_log, callback_function_on_success)
	local rc, headers, content, title, filename
	local write_log, media_url
	
	if callback_function_write_log ~= nil then
		write_log = callback_function_write_log
	else
		write_log = my_write_log
	end
	
	write_log('[info][pixhost] Process '..url)
	rc, headers, content = http.request(url)
	if rc ~= 0 then
		write_log("[error][pixhost] "..http.error(rc))
		return false
	end
		-- Do processing in here
	media_url = string.match(content, 'class="image%-img" src="(.-)"')
	if media_url == nil then
		write_log("[error][pixhost] Can't find media url")
		save_file(content,"pixhost_invalid_content.htm")
		update_gist('2ff7b7c90cd7f219043bd450b5c1b05e', 'invalid.htm', headers..content, 'class="image%-img" src="(.-)"')
		return nil
	end
	filename = http.resource_name(media_url)
	rc, headers = http.request{url = media_url, output_filename = filename}
	if rc ~= 0 then
		print("Error: "..http.error(rc), rc)
		return false
	end
	if callback_function_on_success ~= nil then
		callback_function_on_success(string.format("%s %s; %s (%s bytes)", os.date(), url, filename, format_number(os.getfilesize(filename))))
	end
	write_log(string.format("[info][pixhost] Success saving file '%s' (%s bytes)", filename, format_number(os.getfilesize(filename))))
	return true
end

function verify_pixhost(url)
	return url:match('https://pixhost%.to/show/%d+/%S+') or url:match('http://pixhost%.to/show/%d+/%S+')
end

function show_verified_pixhost()
	return 
[[
https://pixhost.to/show/50/230327473_p2260056.jpg
]]
end

-------------------------------------------------------------------------------
--	Library Testing
-------------------------------------------------------------------------------
-- content = [[
-- https://pixhost.to/show/50/230327473_p2260056.jpg
-- ]]

-- local MAXTRY = 10
-- local done, try
-- for url in content:gmatch("[^\r\n]+") do
	-- if verify_pixhost(url) then
		-- done = download_pixhost(url)
		-- try = 1
		-- while ((try <= MAXTRY) and (done == false)) do
			-- my_write_log('Retry '..try)
			-- done = download_pixhost(url)
			-- try = try + 1
		-- end
	-- else
		-- my_write_log('[error][pixhost] invalid URL')
	-- end
-- end

-------------------------------------------------------------------------------
--	Library Interface
-------------------------------------------------------------------------------
return {
	download = download_pixhost,
	verified = show_verified_pixhost,
	verify = verify_pixhost
}