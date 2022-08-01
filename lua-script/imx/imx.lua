-- Lua 5.1.5.XL Script for downloading media from https://imx.to
-- Interpreter : luaX https://github.com/dhaninovan/luax/releases/download/v5.1.5.77/lua.exe
-- Rawamangun, dhani.novan@gmail.com 15/05/2021

dofile('../strict.lua')
dofile('../common.lua')

function my_write_log(data)
	print(os.date("%d/%m/%Y %H:%M:%S ")..data)
end

-- Output :
--	true : on success
--	false : timeout
--	nil : invalid response and other fail status
function download_imx(url, callback_function_write_log, callback_function_on_success)
	local rc, headers, content, title, filename
	local write_log, media_url
	
	if callback_function_write_log ~= nil then
		write_log = callback_function_write_log
	else
		write_log = my_write_log
	end
	
	write_log('[info][imx] Process '..url)
	rc, headers, content = http.request(url)
	if rc ~= 0 then
		write_log("[error][imx] "..http.error(rc))
		return false
	end
	-- Do processing in here
	rc, headers, content = http.request(url,'imgContinue=Continue to your image...')
	if rc ~= 0 then
		write_log("[error][imx] "..http.error(rc))
		return false
	end
	media_url, filename = content:match('<img class="centred" src="(.-)" alt="(.-)"')
	if media_url == nil or filename == nil then write_log('[error][imx] invalid response. (1)') save_file(content, 'imx_invalid_content.htm') return nil end
	if string.find(filename,'.jpg',1,true) == nil then filename = filename..'.jpg' end
	
	http.set_conf(http.OPT_TIMEOUT, 30)
	rc, headers = http.request{url = media_url, output_filename = filename}
	if rc ~= 0 then
		write_log("[error][imx] "..http.error(rc))
		return false
	end
	
	if callback_function_on_success ~= nil then
		callback_function_on_success(string.format("%s %s; %s (%s bytes)", os.date(), url, filename, format_number(os.getfilesize(filename))))
	end
	write_log(string.format("[info][imx] Success saving file '%s' (%s bytes)", filename, format_number(os.getfilesize(filename))))
	return true
end

function verify_imx(url)
	return url:match('https://imx%.to/./%w') or url:match('https://imx%.to/img%-.-html')
end

function show_verified_imx()
	return 
[[
https://imx.to/i/1rjpjo
https://imx.to/img-586f3679c3e44.html
]]
end

-------------------------------------------------------------------------------
--	Library Testing
-------------------------------------------------------------------------------
-- Source url = 'https://nnsets.fr/viewtopic.php?f=6&t=425&start=25' -- MarvelCharm Photos Page 2
-- content = [[
-- https://imx.to/i/1rjs5l
-- https://imx.to/i/1rjs6i
-- ]]

-- local MAXTRY = 10
-- local done, try
-- for url in content:gmatch("[^\r\n]+") do
	-- if verify_imx(url) then
		-- done = download_imx(url)
		-- try = 1
		-- while ((try <= MAXTRY) and (done == false)) do
			-- my_write_log('Retry '..try)
			-- done = download_imx(url)
			-- try = try + 1
		-- end
	-- else
		-- my_write_log('[error][imx] invalid URL')
	-- end
-- end

-------------------------------------------------------------------------------
--	Library Interface
-------------------------------------------------------------------------------
return {
	download = download_imx,
	verified = show_verified_imx,
	verify = verify_imx
}