-- Lua 5.1.5.XL Script for downloading media in https://filedot.xyz/
-- Host filedot can't accept Range, it really sucks
-- Interpreter : luaX https://drive.google.com/file/d/1gaDQVusrvp78HfQbswVx4Wr-4-plA4Ke/view?usp=sharing
-- 15/01/2021 Jakarta Rawamangun, dhani.novan@gmail.com

dofile('../strict.lua')
dofile('../common.lua')

local MAXTIMEOUT = 3600	-- set max timeout 60 minutes

-- Output :
--	true : on success
--	false : timeout
--	nil : invalid response and other fail status
function download_filedot(url, callback_function_write_log, callback_function_on_success)
	local rc, headers, content, tcode, n, id, code, rand, countdown, filename, post_data, url2, size
	local write_log
	
	if callback_function_write_log ~= nil then
		write_log = callback_function_write_log
	else
		write_log = my_write_log
	end
	
	id = url:match('xyz/(.-)$')
	if id == nil then write_log('[error][filedot] invalid input url. Format: https://filedot.xyz/ididididid') return nil end

	write_log('[info][filedot] Process '..url)
	rc, headers, content = http.request(url)
	if rc ~= 0 then
		write_log("[error][filedot] "..http.error(rc), rc)
		return false
	end
	
	filename = string.match(content, 'fname" value="(.-)">')
	rc, headers, content = http.request(url,'op=download1&usr_login=&referer=https://nnsets.fr/&method_free=Free+Download+>>&id='..id..'&fname='..filename)
	if rc ~= 0 then
		print("Error: "..http.error(rc), rc)
		return false
	end
	-- print(content)
	-- print(headers)
	
	countdown = content:match('<span class="seconds">(%d-)</span>')
	if countdown == nil then write_log('[error][filedot] invalid response. (1)') save_file(content, 'filedot_invalid_content.htm') return nil end
	-- write_log('[info][filedot] Waiting '..countdown)
	if os.info() == "Linux" then
		os.execute('sleep '..countdown)
	else
		os.execute('timeout '..countdown)
	end
	
	tcode = {}
	n = 0
	for seq, code in content:gmatch("padding%-left%:(%d-)px%;padding%-top%:%d-px;'>%&%#(%d-)%;</span>") do
		if n < 4 then
			table.insert(tcode, {tonumber(seq), tonumber(code)-48})
		end
		n = n + 1
	end
	if n < 4 then write_log('[error][filedot] invalid response. (2)') save_file(content, 'filedot_invalid_content.htm') return nil end
	table.sort(tcode, function(a,b) return a[1]<b[1] end)
	code = string.format("%d%d%d%d", tcode[1][2], tcode[2][2], tcode[3][2], tcode[4][2])
	-- write_log('[info][filedot] Code: '..code)
	
	rand = content:match('<input type="hidden" name="rand" value="(.-)">')
	if rand == nil then write_log('[error] invalid response. (3)') save_file(content, 'filedot_invalid_content.htm') return nil end
	
	post_data = string.format("op=download2&id=%s&rand=%s&referer=&method_free=Free+Download+>>&method_premium=&adblock_detected=0&code=%s", id, rand, code)	
	rc, headers, content = http.request(url, post_data)
	if rc ~= 0 then
		write_log("[error][filedot] "..http.error(rc), rc)
		return false
	end
	size = content:match('<span style="font%-size%:12px; color%:%#4c4c4c%;">(.-)<small>')
	url2 = content:match('class="bigres"><a href="(.-)">')
	if url2 == nil or size == nil then write_log('[error] invalid response. (5)') save_file(content, 'filedot_invalid_content.htm') return nil end
	write_log('[info][filedot] Downloading '..filename..' Size: '..size)
	n = 0
	rc = 0
	http.set_conf(http.OPT_REFERER, url)
	http.set_conf(http.OPT_TIMEOUT, MAXTIMEOUT)
	rc, headers = http.request{url = url2, output_filename = filename}
	if rc ~= 0 then
		write_log("[error][filedot] "..http.error(rc), rc)
		return false
	end

	if callback_function_on_success ~= nil then
		callback_function_on_success(string.format("%s %s; %s (%s bytes)", os.date(), url, filename, format_number(os.getfilesize(filename))))
	end
	write_log(string.format("[info][filedot] Success saving file '%s' (%s bytes)", filename, format_number(os.getfilesize(filename))))
	return true
end

function verify_filedot(url)
	return url:match('https://filedot%.xyz/%w') or url:match('http://filedot%.xyz/%w')
end

function show_verified_filedot()
	return 
[[
http://filedot.xyz/fky4zh5v0e1r
https://filedot.xyz/fky4zh5v0e1r
]]
end

-------------------------------------------------------------------------------
--	Library Testing
-------------------------------------------------------------------------------
-- content = [[
-- https://filedot.xyz/fky4zh5v0e1r
-- ]]

-- for url in content:gmatch("[^\r\n]+") do
	-- if verify_filedot(url) then
		-- download_filedot(url)
	-- else
		-- my_write_log('[error][filedot] invalid URL')
	-- end
-- end


-------------------------------------------------------------------------------
--	Library Interface
-------------------------------------------------------------------------------
return {
	download = download_filedot,
	verified = show_verified_filedot,
	verify = verify_filedot
}


-- Source url : 
-- https://nnsets.fr/viewtopic.php?f=6&p=10813	GeorgeModels.com - Heidy Pino 
-- https://nnsets.fr/viewtopic.php?f=9&t=310 
-- https://nnsets.fr/viewtopic.php?f=6&t=159&start=325
