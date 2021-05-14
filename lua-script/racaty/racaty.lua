-- Lua Library : Download file from racaty.net
-- Format Input URL = 
--		  https://racaty.net/%w+
--			https://racaty.net/wzevnbbgfvhk
-- Interpreter : modified lua https://github.com/dhaninovan/luax/releases/download/v5.1.5.77/lua.exe
-- 5:30 04 August 2020, Rawamangun

dofile('../strict.lua')
dofile('../common.lua')

function my_write_log(data)
	print(os.date("%d/%m/%Y %H:%M:%S ")..data)
end

-- GLOBAL SETTING
local MAXTIMEOUT = 1800	-- set max timeout 30 minutes

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

-- Output :
--	true : on success
--	false : fail, timeout or network problem (can be retried)
--	nil : fail, invalid response
function download_racaty(url, callback_function_write_log, callback_function_on_success)
	local rc, content, filename, direct_url, id
	local write_log, headers
 
	if callback_function_write_log ~= nil then
		write_log = callback_function_write_log
	else
		write_log = my_write_log
	end
	
	rc, headers, content = http.request(url)
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
	rc, headers, content = http.request(url,'op=download2&rand=&method_free=&method_premium=&referer='..url..'&id='..id)
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
	
	direct_url = string.match(content, '<a style="visibility: hidden;" id="uniqueExpirylink" href="(.-)"></a>')
	if direct_url == nil then
		write_log("[error][racaty.download] Can't find direct link. Invalid response from racaty.net")
		save_file(content,"racaty_invalid_content.htm")
		return nil
	end
	direct_url = urlencode(direct_url)
	http.set_conf(http.OPT_TIMEOUT, MAXTIMEOUT)
	rc, headers = http.request{url = direct_url, output_filename = filename}
	if rc ~= 0 then
		write_log("[error][racaty.download] "..http.error(rc))
		return false
	end
	
	-- Update success list of URL
	if callback_function_on_success ~= nil then callback_function_on_success(string.format("%s %s; '%s' (%s bytes)", os.date(), url, filename, format_number(os.getfilesize(filename)))) end
	write_log(string.format("[warning][racaty.download] Success saving file '%s' (%s bytes)", filename, format_number(os.getfilesize(filename))))
	return true
end

function verify_racaty(url)
	return url:match('^https://racaty%.net/%w+')
end

function show_verified_racaty()
	return 
[[
https://racaty.net/n17pnjv54rfq
]]
end

return {
	download = download_racaty,
	verified = show_verified_racaty,
	verify = verify_racaty
}
