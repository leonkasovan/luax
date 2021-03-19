-- Lua Library : Download file from letsupload.io
-- Format Input URL = 
--		https://letsupload.io/%w+
--		https://letsupload.io/n1lH
-- Interpreter : modified lua https://drive.google.com/file/d/1imqMbflxEEc8OsTCJoHiuMufdAfJTNSg/view?usp=drivesdk
-- 5:22 06 August 2020, Rawamangun

dofile('../strict.lua')
dofile('../common.lua')

-- GLOBAL SETTING
local MAXTIMEOUT = 900	-- set max timeout 15 minutes

-- Output :
--	true : on success
--	false : fail, timeout or network problem (can be retried)
--	nil : fail, invalid response
function download_letsupload(url, callback_function_write_log, callback_function_on_success)
	local rc, content, filename, filesize, direct_url, id, uid, headers
	local write_log, original_url
 
	original_url = url
	if callback_function_write_log ~= nil then
		write_log = callback_function_write_log
	else
		write_log = print
	end
	
	if url:match('^https://www.letsupload.io/%w+') then	--Normalize URL
		url = 'https://letsupload.io/'..string.match(url, 'letsupload.io/(%w+)')
	end
	
	rc, headers, content = http.request(url)
	if rc ~= 0 then
		write_log("[error][letsupload.download] "..http.error(rc))
		return false
	end
		
	filename = string.match(content, '<span class="h3">(.-)</span>')
	filesize = string.match(content, 'Filesize:</span>%s+<span>(.-)</span>')
	if filename == nil or filesize == nil then
		write_log("[error][letsupload.download] Can't find filename / filesize. Invalid response from letsupload.io")
		save_file(content,"letsupload_invalid_content.htm")
		return nil
	end
	
	url = string.match(content, "window.location = '(.-)'; return false;\">download</button>")
	if url == nil then
		write_log("[error][letsupload.download] Can't find download link. Invalid response from letsupload.io")
		save_file(content,"letsupload_invalid_content.htm")
		return nil
	end
	http.set_conf(http.OPT_TIMEOUT, MAXTIMEOUT)
	rc, headers, content = http.request(url)
	if rc ~= 0 then
		write_log("[error][letsupload.download] "..http.error(rc))
		return false
	end
	uid = string.match(content, 'showFileInformation%((%d+)%);')
	if uid == nil then
		write_log("[error][letsupload.download] Can't find post data in showFileInformation(uid). Check letsupload_invalid_content.htm")
		save_file(content,"letsupload_invalid_content.htm")
		return nil
	end
	
	rc, headers, content = http.request('https://letsupload.io/account/ajax/file_details','u='..uid)
	if rc ~= 0 then
		print("Error: "..http.error(rc), rc)
		return false
	end
	direct_url = content:match('triggerFileDownload%((%d+),')
	if direct_url ~= nil then	-- Permissions : Download
		direct_url = 'https://letsupload.io/account/direct_download/'..uid
	else -- Permissions : View Video
		direct_url = content:match('data%-video%-source=\\"%[{source%:\'(.-)\'')
		if direct_url == nil then
			write_log("[error][letsupload.download] Can't find download link. Invalid response from letsupload.io. Check letsupload_invalid_content.json")
			save_file(content,"letsupload_invalid_content.json")
			return nil
		end
		direct_url = direct_url:gsub('\\/','/')
	end
	http.set_conf(http.OPT_REFERER, url)
	http.set_conf(http.OPT_TIMEOUT, MAXTIMEOUT)
	rc, headers = http.request{url = direct_url, output_filename = filename}
	if rc ~= 0 then
		write_log("[error][letsupload.download] "..http.error(rc))
		return false
	end
	
	-- Update success list of URL
	if callback_function_on_success ~= nil then callback_function_on_success(string.format("%s %s; %s (%s)", os.date(), original_url, filename, filesize)) end
	write_log(string.format("[info][letsupload.download] Success saving file %s (%s)", filename, filesize))
	return true
end

function verify_letsupload(url)
	return url:match('^https://letsupload.io/%w+')
	or url:match('^https://www.letsupload.io/%w+')
end

function show_verified_letsupload()
	return 
[[
https://letsupload.io/27bTf
https://www.letsupload.io/28egf/
]]
end

-------------------------------------------------------------------------------
--	Library Testing
-------------------------------------------------------------------------------
-- content = [[
-- https://letsupload.io/27chz
-- ]]

-- for url in content:gmatch("[^\r\n]+") do
	-- if verify_letsupload(url) then
		-- download_letsupload(url)
	-- else
		-- my_write_log('[error][filedot] invalid URL')
	-- end
-- end

return {
	download = download_letsupload,
	verified = show_verified_letsupload,
	verify = verify_letsupload
}
