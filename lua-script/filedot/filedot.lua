-- Lua 5.1.5.XL Script for downloading media in https://filedot.xyz/
-- Interpreter : luaX https://drive.google.com/file/d/1gaDQVusrvp78HfQbswVx4Wr-4-plA4Ke/view?usp=sharing
-- 15/01/2021 Jakarta Rawamangun, dhani.novan@gmail.com

-- require('strict')
local LOG_FILE = "filedot.log"
-- local DEBUG = true	-- write all log to a file (LOG_FILE)
local DEBUG = false	-- write all log to console output

function format_number(v)
	local s
	local unary
	
	if v < 0 then
		s = tostring(-v)
		unary = "-"
	else
		s = tostring(v)
		unary = ""
	end
    
    local pos = string.len(s) % 3

    if pos == 0 then pos = 3 end
    return unary..string.sub(s, 1, pos).. string.gsub(string.sub(s, pos+1), "(...)", ".%1")
end

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
		print(os.date()..data)
		return true
	end
end

-- Output :
--	true : on success
--	false : invalid response, timeout, other fail status
function download_filedot(url, callback_function_write_log, callback_function_on_success)
	local rc, headers, content, tcode, n, id, code, rand, countdown, filename, post_data, url2, size
	local write_log
	
	if callback_function_write_log ~= nil then
		write_log = callback_function_write_log
	else
		write_log = my_write_log
	end
	
	id = url:match('xyz/(.-)$')
	if id == nil then write_log('[error][filedot] invalid input url. Format: https://filedot.xyz/ididididid') return false end

	write_log('[info][filedot] Process '..url)
	rc, headers, content = http.request(url)
	if rc ~= 0 then
		write_log("[error][filedot] "..http.error(rc), rc)
		return false
	end
	countdown = content:match('<span class="seconds">(%d-)</span>')
	if countdown == nil then write_log('[error][filedot] invalid response. (1)') return false end
	write_log('[info][filedot] Waiting '..countdown)
	os.execute('timeout '..countdown)
	
	tcode = {}
	n = 0
	for seq, code in content:gmatch("padding%-left%:(%d-)px%;padding%-top%:%d-px;'>%&%#(%d-)%;</span>") do
		if n < 4 then
			table.insert(tcode, {tonumber(seq), tonumber(code)-48})
		end
		n = n + 1
	end
	if n < 4 then write_log('[error][filedot] invalid response. (2)') return false end
	table.sort(tcode, function(a,b) return a[1]<b[1] end)
	code = string.format("%d%d%d%d", tcode[1][2], tcode[2][2], tcode[3][2], tcode[4][2])
	
	rand = content:match('<input type="hidden" name="rand" value="(.-)">')
	if rand == nil then write_log('[error] invalid response. (3)') return false end
	
	filename = content:match('<span class="dfilename">(.-)</span>')
	if filename == nil then write_log('[error][filedot] invalid response. (4)') return false end
	
	post_data = string.format("op=download2&id=%s&rand=%s&referer=&method_free=&method_premium=&adblock_detected=0&code=%s", id, rand, code)
	-- write_log('[info] Post '..post_data)
	rc, headers, content = http.request(url, post_data)
	if rc ~= 0 then
		write_log("[error][filedot] "..http.error(rc), rc)
		return false
	end
	
	size = content:match('<span style="font%-size%:12px; color%:%#4c4c4c%;">(.-)<small>')
	url2 = content:match('class="bigres"><a href="(.-)">')
	if url2 == nil or size == nil then write_log('[error] invalid response. (5)') return false end
	write_log('[info][filedot] Downloading '..filename..' Size: '..size)
	n = 0
	rc = 0
	http.set_conf(http.OPT_REFERER, url)
	http.set_conf(http.OPT_TIMEOUT, 1800)
	repeat
		os.execute('del "'..filename..'"')
		if rc ~= 0 then write_log('[error][filedot] Retry '..n..': resuming from '..os.getfilesize(filename)) end
		rc, headers = http.request{url = url2, output_filename = filename}
		n = n + 1
	until rc ~= 28
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



-------------------------------------------------------------------------------
--	Library Testing
-------------------------------------------------------------------------------
-- content = [[
-- http://filedot.xyz/a2xpyuk6wy7b
-- http://filedot.xyz/3glqb9dfislk
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
	verify = verify_filedot
}


-- Source url : 
-- https://nnsets.fr/viewtopic.php?f=6&p=10813	GeorgeModels.com - Heidy Pino 
-- https://nnsets.fr/viewtopic.php?f=9&t=310 
-- https://nnsets.fr/viewtopic.php?f=6&t=159&start=325