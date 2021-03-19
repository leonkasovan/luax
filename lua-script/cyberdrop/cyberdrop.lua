-- Lua 5.1.5.XL Script for downloading media in https://cyberdrop.me/a/nY0LCDNk
-- Interpreter : luaX https://drive.google.com/file/d/1gaDQVusrvp78HfQbswVx4Wr-4-plA4Ke/view?usp=sharing
-- 15/01/2021 Jakarta Rawamangun, dhani.novan@gmail.com

dofile('../strict.lua')
dofile('../common.lua')

local MAXTIMEOUT = 3600	-- set max timeout 60 minutes
local FAIL_FILENAME = "cyberdrop_failed.txt"

-- Output :
--	true : on success
--	false : timeout
--	nil : invalid response and other fail status
function download_cyberdrop(url, callback_function_write_log, callback_function_on_success)
	local rc, headers, content, title, ndownloaded, nfail
	local write_log, fo
	
	if callback_function_write_log ~= nil then
		write_log = callback_function_write_log
	else
		write_log = print
	end
	
	write_log('[info][cyberdrop] Process '..url)
	rc, headers, content = http.request(url)
	if rc ~= 0 then
		write_log("[error][cyberdrop] "..http.error(rc))
		return false
	end
	
	title = content:match('<h1 id="title" class="title has%-text%-centered" title="(.-)">')
	if title == nil then write_log('[error][cyberdrop] invalid response. (1)') save_file(content, 'cyberdrop_invalid_content.htm') return nil end
	
	fo = io.open(FAIL_FILENAME, "w")
	if fo == nil then
		write_log('[error][cyberdrop] Can not open a file '..FAIL_FILENAME)
		return nil
	end
	
	ndownloaded = 0
	nfail = 0
	for pic_url, pic_name in content:gmatch('<a id="file" href="(.-)" target="%_blank" title="(.-)"') do
		rc, headers = http.request{url = pic_url, output_filename = pic_name}
		if rc ~= 0 then
			write_log("[error][cyberdrop] "..pic_url..': '..http.error(rc))
			fo:write(pic_url..'\n')
			nfail = nfail + 1
		else
			write_log("[info][cyberdrop] "..pic_url..' done')
			ndownloaded = ndownloaded + 1
		end
	end
	fo:close()
	
	if ndownloaded == 0 then
		write_log("[error][cyberdrop] Nothing has downloaded")
		return nil
	end
	
	write_log("[info][cyberdrop] "..ndownloaded..' files downloaded. ')
	if nfail ~= 0 then write_log("[warn][cyberdrop] "..nfail..' files failed and the list is in '..FAIL_FILENAME) end
	print('Moving to '..title)
	os.execute('mkdir "'..title..'"')
	if os.info() == "Linux" then
		os.execute('mv -f *.jpg "'..title..'"')
		else
		os.execute('move *.jpg "'..title..'"')
	end
	
	if callback_function_on_success ~= nil then
		callback_function_on_success(string.format("%s: %s(%s) %d success. %d fail", os.date(), url, title, ndownloaded, nfail))
	end
	return true
end

function verify_cyberdrop(url)
	return url:match('https://cyberdrop%.me/%w/%w+')
end

function show_verified_cyberdrop()
	return 
[[
https://cyberdrop.me/a/BZ0ZS5Ry
]]
end

-------------------------------------------------------------------------------
--	Library Testing
-------------------------------------------------------------------------------
-- content = [[
-- https://cyberdrop.me/a/FKTTaPQZ
-- https://cyberdrop.me/a/nY0LCDNk
-- ]]

-- for url in content:gmatch("[^\r\n]+") do
	-- if verify_cyberdrop(url) then
		-- download_cyberdrop(url)
	-- else
		-- my_write_log('[error][cyberdrop] invalid URL')
	-- end
-- end

-------------------------------------------------------------------------------
--	Library Interface
-------------------------------------------------------------------------------
return {
	download = download_cyberdrop,
	verified = show_verified_cyberdrop,
	verify = verify_cyberdrop
}


-- Source url : 
-- Google site:cyberdrop.me
