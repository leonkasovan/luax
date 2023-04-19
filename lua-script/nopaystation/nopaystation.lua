-- Lua 5.1.5.XL Script for downloading PKG installer from https://nopaystation.com
-- Interpreter : luaX 
-- dhani.novan@gmail.com 10:14 17 April 2023 Jakarta

dofile('../strict.lua')
dofile('../common.lua')

function my_write_log(data)
	print(os.date("%d/%m/%Y %H:%M:%S ")..data)
end

-- Output :
--	true : on success
--	false : timeout
--	nil : invalid response and other fail status
function download_nopaystation(url, callback_function_write_log, callback_function_on_success)
	local rc, headers, content, title, filename
	local write_log, pkg_url, rap_url
	
	if callback_function_write_log ~= nil then
		write_log = callback_function_write_log
	else
		write_log = my_write_log
	end
	
	write_log('[info][nopaystation] Process '..url)
	http.set_conf(http.OPT_TIMEOUT, 3600)
	rc, headers, content = http.request(url)
	if rc ~= 0 then
		write_log("[error][nopaystation|download_nopaystation] "..http.error(rc))
		return false
	end
	
	-- Download the RAP
	filename = string.match(content, 'contentId" value="(.-)" readonly')
	if filename == nil then
		write_log("[error][nopaystation|download_nopaystation] Invalid response. Can't find ContentID of PKG")
		return false
	end
	filename = filename..".rap"
	if os.getfilesize(filename) == 0 then
		rap_url = string.match(content, 'rap" href="(.-)">Download RAP')
		if rap_url == nil then
			write_log("[warning][nopaystation|download_nopaystation] Invalid response. Can't find URL of RAP")
		else		
			rap_url = "http://nopaystation.com"..rap_url
			rc, headers = http.request{url = rap_url, output_filename = filename}
			if rc ~= 0 then
				write_log("[error][nopaystation|download_nopaystation] "..http.error(rc))
				return false
			end
			if callback_function_on_success ~= nil then
				callback_function_on_success(string.format("%s %s; %s (%s bytes)", os.date(), url, filename, format_number(os.getfilesize(filename))))
			end
			write_log(string.format("[info][nopaystation] Success saving file '%s' (%s bytes)", filename, format_number(os.getfilesize(filename))))
		end
	end

	
	-- Download the PKG
	filename = string.match(content, 'class="mb%-2">(.-)</h4>')
	if filename == nil then
		write_log("[error][nopaystation|download_nopaystation] Invalid response. Can't find Title of PKG")
		return false
	end
	filename = filename:gsub("%W","_")..".pkg"
	pkg_url = url:gsub("%?version","/pkg%?version")
	http.set_conf(http.OPT_NOPROGRESS, false)
	http.set_conf(http.OPT_PROGRESS_TYPE, 3)
	rc, headers = http.request{url = pkg_url, output_filename = filename}
	http.set_conf(http.OPT_NOPROGRESS, true)
	if rc ~= 0 then
		write_log("[error][nopaystation|download_nopaystation] "..http.error(rc))
		return false
	end
	if callback_function_on_success ~= nil then
		callback_function_on_success(string.format("%s %s; %s (%s bytes)", os.date(), url, filename, format_number(os.getfilesize(filename))))
	end
	write_log(string.format("[info][nopaystation] Success saving file '%s' (%s bytes)", filename, format_number(os.getfilesize(filename))))
	
	return true
end

function verify_nopaystation(url)
	return url:match('http://nopaystation%.com/view/%w+/%w+/%w+/%d+') or url:match('https://nopaystation%.com/view/%w+/%w+/%w+/%d+')
end

function show_verified_nopaystation()
	return 
[[
http://nopaystation.com/view/PS3/NPEB00076/BOMBERMANGAME001/1?version=1.01
]]
end


-------------------------------------------------------------------------------
--	Library Interface
-------------------------------------------------------------------------------
return {
	download = download_nopaystation,
	verified = show_verified_nopaystation,
	verify = verify_nopaystation
}