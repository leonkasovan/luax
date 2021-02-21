-- Lua Library : Download file from racaty.net
-- Format Input URL = 
--		  https://racaty.net/%w+
--			https://racaty.net/wzevnbbgfvhk
-- Interpreter : modified lua https://drive.google.com/file/d/1imqMbflxEEc8OsTCJoHiuMufdAfJTNSg/view?usp=drivesdk
-- 5:30 04 August 2020, Rawamangun

-- GLOBAL SETTING
local MAXTIMEOUT = 900	-- set max timeout 15 minutes
local LOG_FILE = "racaty.log"
local DEBUG = true	-- write all log to a file (LOG_FILE)
--local DEBUG = false	-- write all log to console output

function format_number(s)
    local pos = string.len(s) % 3

    if pos == 0 then pos = 3 end
    return string.sub(s, 1, pos).. string.gsub(string.sub(s, pos+1), "(...)", ".%1")
end

local char_to_hex = function(c)
  return string.format("%%%02X", string.byte(c))
end

local function urlencode(url)
  if url == nil then
    return
  end
  url = url:gsub("\n", "\r\n")
  url = url:gsub("([^%w _%%%-%.~%/%:])", char_to_hex)
  url = url:gsub(" ", "+")
  return url
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
function download_racaty(url, callback_function_write_log, callback_function_on_success)
	local rc, content, filename, direct_url, id, md5_host
	local write_log
 
	if callback_function_write_log ~= nil then
		write_log = callback_function_write_log
	else
		write_log = my_write_log
	end
	
	rc, content = http.get_url(url)
	if rc ~= 0 then
		write_log("[error][racaty.download] "..http.error(rc))
		return false
	end
	
	id = url:match('https://racaty.net/(%w+)')
	if id == nil then
		write_log("[error][racaty.download] Can't find ID. Invalid URL")
		return nil
	end
	
	http.set_conf(http.OPT_TIMEOUT, MAXTIMEOUT)
	rc, content = http.post_form(url, 'op=download2&rand=&method_free=&method_premium=&referer='..url..'&id='..id)
	if rc ~= 0 then
		write_log("[error][racaty.download] "..http.error(rc))
		return false
	end
	
	filename = string.match(content, 'ellipsis;">(.-)</p>')
	if filename == nil then
		write_log("[error][racaty.download] Can't find filename. Invalid response from racaty.net")
		save_file(content,"racaty_invalid_content.htm")
		return nil
	end
	
	md5_host = string.match(content, 'MD5: </h7><code class="d%-block subtitle">(.-)</code>')
	if md5_host == nil then md5_host = "" end
	
	direct_url = string.match(content, '<a style="visibility: hidden;" id="uniqueExpirylink" href="(.-)"></a>')
	if direct_url == nil then
		write_log("[error][racaty.download] Can't find direct link. Invalid response from racaty.net")
		save_file(content,"racaty_invalid_content.htm")
		return nil
	end
	direct_url = urlencode(direct_url)
	http.set_conf(http.OPT_TIMEOUT, MAXTIMEOUT)
	rc = http.get_url(direct_url, filename)
	if rc ~= 0 then
		write_log("[error][racaty.download] "..http.error(rc))
		return false
	end
	
	-- Update success list of URL
	os.remove('http_header.txt')
	if callback_function_on_success ~= nil then callback_function_on_success(string.format("%s %s; '%s' (%s bytes)", os.date(), url, filename, format_number(os.getfilesize(filename)))) end
	if os.checksum(filename) == md5_host then
		write_log(string.format("[info][racaty.download] Success saving file '%s' (%s bytes) MD5 checksum OK", filename, format_number(os.getfilesize(filename))))
	else
		write_log(string.format("[warning][racaty.download] Success saving file '%s' (%s bytes) but MD5 checksum fail", filename, format_number(os.getfilesize(filename))))
	end
	return true
end

function verify_racaty(url)
	return url:match('^https://racaty%.net/%w+')
end

return {
	download = download_racaty,
	verify = verify_racaty
}
