-- Lua 5.1.5.XL Script for downloading media from https://pixeldrain.com
-- Interpreter : luaX https://drive.google.com/file/d/1gaDQVusrvp78HfQbswVx4Wr-4-plA4Ke/view?usp=sharing

dofile('../strict.lua')
dofile('../common.lua')

function my_write_log(data)
	print(os.date("%d/%m/%Y %H:%M:%S ")..data)
end

-- Output :
--	true : on success
--	false : timeout
--	nil : invalid response and other fail status
function download_pixeldrain(url, callback_function_write_log, callback_function_on_success)
	local rc, headers, content, title, filename
	local write_log, media_url
	
	if callback_function_write_log ~= nil then
		write_log = callback_function_write_log
	else
		write_log = my_write_log
	end
	
	write_log('[info][pixeldrain] Process '..url)
	rc, headers, content = http.request(url)
	if rc ~= 0 then
		write_log("[error][pixeldrain] "..http.error(rc))
		return nil
	end
	filename = string.match(content, 'og%:title" content="(.-)"')
	if filename == nil then write_log('[error][pixeldrain] invalid response. (1)') save_file(content, 'pixeldrain_invalid_content.htm') return nil end
	
	-- Do processing in here
	http.set_conf(http.OPT_TIMEOUT, 1800)
	http.set_conf(http.OPT_REFERER, url)
	rc, headers = http.request{url = 'https://pixeldrain.com/api/file/'..url:match('pixeldrain%.com/u/(%w+)')..'?download', output_filename = filename}
	if rc ~= 0 then
		write_log("[error][pixeldrain] "..http.error(rc))
		return false
	end
	
	if callback_function_on_success ~= nil then
		callback_function_on_success(string.format("%s %s; %s (%s bytes)", os.date(), url, filename, format_number(os.getfilesize(filename))))
	end
	write_log(string.format("[info][pixeldrain] Success saving file '%s' (%s bytes)", filename, format_number(os.getfilesize(filename))))
	return true
end

-- Output :
--	true : on success
--	false : timeout
--	nil : invalid response and other fail status
function download_pixeldrain_list(url, callback_function_write_log, callback_function_on_success)
	local rc, headers, content, title, filename
	local write_log, media_url
	
	if callback_function_write_log ~= nil then
		write_log = callback_function_write_log
	else
		write_log = my_write_log
	end
	
	write_log('[info][pixeldrain] Process '..url)
	rc, headers, content = http.request(url)
	if rc ~= 0 then
		write_log("[error][pixeldrain] "..http.error(rc))
		return nil
	end
	title = string.match(content, 'og%:title" content="(.-)"')
	if title == nil then write_log('[error][pixeldrain] invalid response. (1)') save_file(content, 'pixeldrain_invalid_content.htm') return nil end
	filename = string.format("%s (%s).zip", title, url:match('pixeldrain%.com/l/(%w+)'))
	write_log(filename)
	
	-- Do processing in here
	http.set_conf(http.OPT_TIMEOUT, 1800)
	http.set_conf(http.OPT_REFERER, url)
	rc, headers = http.request{url = 'https://pixeldrain.com/api/list/'..url:match('pixeldrain%.com/l/(%w+)')..'/zip', output_filename = filename}
	write_log(filename..' https://pixeldrain.com/api/list/'..url:match('pixeldrain%.com/l/(%w+)')..'/zip')
	if rc ~= 0 then
		write_log("[error][pixeldrain] "..http.error(rc))
		return false
	end
	
	if callback_function_on_success ~= nil then
		callback_function_on_success(string.format("%s %s; %s (%s bytes)", os.date(), url, filename, format_number(os.getfilesize(filename))))
	end
	write_log(string.format("[info][pixeldrain] Success saving file '%s' (%s bytes)", filename, format_number(os.getfilesize(filename))))
	return true
end

function verify_pixeldrain(url)
	return url:match('https://pixeldrain%.com/u/%w') or url:match('http://pixeldrain%.com/u/%w')
end

function verify_pixeldrain_list(url)
	return url:match('https://pixeldrain%.com/l/%w') or url:match('http://pixeldrain%.com/l/%w')
end

function show_verified_pixeldrain()
	return 
[[
https://pixeldrain.com/u/Nok49TmP
https://pixeldrain.com/l/wYSnZfoS
]]
end

-------------------------------------------------------------------------------
--	Library Testing
-------------------------------------------------------------------------------
-- https://pixeldrain.com/u/Nok49TmP
-- https://pixeldrain.com/u/1rHPNrV8;Bite the Bullet;487MB 
-- https://pixeldrain.com/u/3UA3qYJY

-- content = [[
-- https://pixeldrain.com/l/wYSnZfoS
-- ]]

-- for url in content:gmatch("[^\r\n]+") do
	-- if verify_pixeldrain(url) then
		-- download_pixeldrain(url)
	-- elseif verify_pixeldrain_list(url) then
		-- download_pixeldrain_list(url)
	-- else
		-- my_write_log('[error][pixeldrain] invalid URL')
	-- end
-- end

-------------------------------------------------------------------------------
--	Library Interface
-------------------------------------------------------------------------------
return {
	download = download_pixeldrain,
	verify = verify_pixeldrain,
	download_list = download_pixeldrain_list,
	verify_list = verify_pixeldrain_list,
	verified = show_verified_pixeldrain
}
