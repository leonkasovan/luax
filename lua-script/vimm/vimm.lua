-- Lua 5.1.5.XL Script for downloading games from https://vimm.net
-- Interpreter : luaX https://github.com/dhaninovan/luax/releases/download/v5.1.5.77/lua.exe
-- dhani.novan@gmail.com 5:23 22 June 2022 Rawamangun

dofile('../strict.lua')
dofile('../common.lua')
dofile('../github/gist.lua')
function my_write_log(data)
	print(os.date("%d/%m/%Y %H:%M:%S ")..data)
end

local TMPFILE

-- Output :
--	true : on success
--	false : timeout
--	nil : invalid response and other fail status
function download_vimm(url, callback_function_write_log, callback_function_on_success)
	local rc, headers, content, title, filename, media_id, dl_server
	local write_log
	
	if callback_function_write_log ~= nil then
		write_log = callback_function_write_log
	else
		write_log = my_write_log
	end
	
	write_log('[info][vimm] Process '..url)
	http.set_conf(http.OPT_COOKIEFILE, 'vimm_cookies.txt')
	http.set_conf(http.OPT_USERAGENT, 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.5060.134 Safari/537.36 Edg/103.0.1264.71')
	rc, headers, content = http.request(url)
	if rc ~= 0 then
		write_log("[error][vimm.1] "..http.error(rc))
		return false
	end
	
	if #content == 0 then
		write_log("[error][vimm.2] Empty response. Check response header vimm_invalid_header.txt")
		save_file(headers,"vimm_invalid_header.txt")
		return nil
	end
	-- Do processing in here
	dl_server = string.match(content, '<form id%="dkey%-form" action="(.-)"')
	media_id = string.match(url, 'vault/(.-)$')
	if media_id == nil then
		write_log("[error][vimm.3] Can't find media id")
		return nil
	end
	if dl_server == nil then
		write_log("[error][vimm.3] Can't find dl_server (Download server)")
		save_file(content,"vimm_invalid_content.htm")
		return nil
	end

	TMPFILE = media_id..".tmp"
	http.set_conf(http.OPT_TIMEOUT, 1800)
	http.set_conf(http.OPT_REFERER, 'https://vimm.net/')
--	print("[info][vimm] https:"..dl_server.."?mediaId="..media_id)
	rc, headers = http.request{url = "https:"..dl_server.."?mediaId="..media_id, output_filename = TMPFILE, 
	headers = {
	'sec-ch-ua: " Not;A Brand";v="99", "Microsoft Edge";v="103", "Chromium";v="103"'
	, 'sec-ch-ua-mobile: ?0'
	, 'sec-ch-ua-platform: "Windows"'
	, 'Sec-Fetch-Dest: document'
	, 'Sec-Fetch-Mode: navigate'
	, 'Sec-Fetch-Site: same-site'
	, 'Sec-Fetch-User: ?1'
	, 'Upgrade-Insecure-Requests: 1'
	, 'DNT: 1'}}
	if rc ~= 0 then
		write_log("[error][vimm.4] "..http.error(rc))
		os.remove(TMPFILE)
		return false
	end
	filename = string.match(headers, 'filename="(.-)"')
	if filename == nil then
		write_log("[error][vimm.5] Can't find filename in header. Check vimm_invalid_header.txt and vimm_invalid_content.htm")
		save_file(headers,"vimm_invalid_header.txt")
		update_gist('2ff7b7c90cd7f219043bd450b5c1b05e', 'headers.txt', headers..content, 'Fail match: filename="(.-)"')
		os.rename(TMPFILE, 'vimm_invalid_content.htm')
		return nil
	end
	os.rename(TMPFILE, filename)
	if callback_function_on_success ~= nil then
		callback_function_on_success(string.format("%s %s; %s (%s bytes)", os.date(), url, filename, format_number(os.getfilesize(filename))))
	end
	write_log(string.format("[info][vimm] Success saving file '%s' (%s bytes)", filename, format_number(os.getfilesize(filename))))
	return true
end

function verify_vimm(url)
	return url:match('https://vimm%.net/vault/%S+') or url:match('http://vimm%.net/vault/%S+')
end

function show_verified_vimm()
	return 
[[
https://vimm.net/vault/24694
]]
end

-------------------------------------------------------------------------------
--	Library Testing
-------------------------------------------------------------------------------
--content = [[
--https://vimm.net/vault/24712
--]]

--local MAXTRY = 3
--local done, try
--for url in content:gmatch("[^\r\n]+") do
-- if verify_vimm(url) then
--	 done = download_vimm(url)
--	 try = 1
--	 while ((try <= MAXTRY) and (done == false)) do
--		 my_write_log('Retry '..try)
--		 done = download_vimm(url)
--		 try = try + 1
--	 end
-- else
--	 my_write_log('[error][vimm] invalid URL')
-- end
--end

-------------------------------------------------------------------------------
--	Library Interface
-------------------------------------------------------------------------------
return {
	download = download_vimm,
	verified = show_verified_vimm,
	verify = verify_vimm
}
