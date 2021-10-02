-- Lua 5.1.5.XL Script for downloading media from https://vipr.im
-- Interpreter : luaX https://github.com/dhaninovan/luax/releases/download/v5.1.5.77/lua.exe
-- dhani.novan@gmail.com 31/12/2021, Rawamangun

dofile('../strict.lua')
dofile('../common.lua')
dofile('../github/gist.lua')
function my_write_log(data)
	print(os.date("%d/%m/%Y %H:%M:%S ")..data)
end

-- Output :
--	true : on success
--	false : timeout
--	nil : invalid response and other fail status
function download_vipr(url, callback_function_write_log, callback_function_on_success)
	local rc, headers, content, title, filename
	local write_log, media_url
	
	if callback_function_write_log ~= nil then
		write_log = callback_function_write_log
	else
		write_log = my_write_log
	end
	
	write_log('[info][vipr] Process '..url)
	rc, headers, content = http.request(url)
	if rc ~= 0 then
		write_log("[error][vipr] "..http.error(rc))
		return false
	end
	
	if #content == 0 then
		write_log("[error][vipr] Empty response. Check response header")
		save_file(headers,"vipr_invalid_header.txt")
		update_gist('2ff7b7c90cd7f219043bd450b5c1b05e', 'invalid.htm', headers, 'Header of Empty response')
		return nil
	end
	
	-- Do processing in here
	media_url = string.match(content, '&nbsp;&nbsp;.<a href="(.-)" download class')
	if media_url == nil then
		write_log("[error][vipr] Can't find media url")
		save_file(content,"vipr_invalid_content.htm")
		update_gist('2ff7b7c90cd7f219043bd450b5c1b05e', 'invalid.htm', content, 'Fail match: &nbsp;&nbsp;.<a href="(.-)" download class')
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
	write_log(string.format("[info][vipr] Success saving file '%s' (%s bytes)", filename, format_number(os.getfilesize(filename))))
	return true
end

function verify_vipr(url)
	return url:match('https://vipr%.im/%S+') or url:match('http://vipr%.im/%S+')
end

function show_verified_vipr()
	return 
[[
https://vipr.im/7bwn8a24aog9
]]
end

-------------------------------------------------------------------------------
--	Library Testing
-------------------------------------------------------------------------------
-- content = [[
-- https://vipr.im/lpv9rp24mjp0
-- ]]

-- local MAXTRY = 10
-- local done, try
-- for url in content:gmatch("[^\r\n]+") do
	-- if verify_vipr(url) then
		-- done = download_vipr(url)
		-- try = 1
		-- while ((try <= MAXTRY) and (done == false)) do
			-- my_write_log('Retry '..try)
			-- done = download_vipr(url)
			-- try = try + 1
		-- end
	-- else
		-- my_write_log('[error][vipr] invalid URL')
	-- end
-- end

-- rc, headers = http.request{url = 'https://vipr.im/gr1rosppf8x6', output_filename = 'vipr_1.htm'}
-- if rc ~= 0 then
	-- print("Error: "..http.error(rc), rc)
	-- return false
-- end
-- print(headers)

-------------------------------------------------------------------------------
--	Library Interface
-------------------------------------------------------------------------------
return {
	download = download_vipr,
	verified = show_verified_vipr,
	verify = verify_vipr
}