-- Lua 5.1.5.XL Script for downloading media from https://imagesbase.ru
-- Interpreter : luaX https://github.com/dhaninovan/luax/releases/download/v5.1.5.77/lua.exe
-- dhani.novan@gmail.com 31/12/2021, Rawamangun

dofile('../strict.lua')
dofile('../common.lua')

IMAGESBASE_USER = 'leonkasovan'
IMAGESBASE_PASS = 'rikadanR1'

function my_write_log(data)
	print(os.date("%d/%m/%Y %H:%M:%S ")..data)
end

function login_imagesbase(user, pass)
	local rc, headers, content
	
	http.set_conf(http.OPT_COOKIEFILE, "imagesbase_cookies.txt")
	rc, headers, content = http.request('https://imagesbase.ru','login_name='..user..'&login_password='..pass..'&login=submit')
	if rc ~= 0 then
		print("Error: "..http.error(rc), rc)
		return false
	end
	return true
end

-- Output :
--	true : on success
--	false : timeout
--	nil : invalid response and other fail status
function download_imagesbase(url, callback_function_write_log, callback_function_on_success)
	local rc, headers, content, title, filename
	local write_log, media_url, image_id, image_dimension
	
	if callback_function_write_log ~= nil then
		write_log = callback_function_write_log
	else
		write_log = my_write_log
	end
	
	write_log('[info][imagesbase] Process '..url)
	image_id, filename = url:match('https://imagesbase%.ru/%S+/(%d+)%-(%S+)%.html')
	if image_id == nil or filename == nil then
		write_log("[error][imagesbase] Cant't find image_id or filename. Invalid url format")
		return nil
	end

	rc, headers, content = http.request(url)
	if rc ~= 0 then
		write_log("[error][imagesbase] "..http.error(rc))
		return false
	end
	-- Do processing in here
	media_url, image_dimension = content:match('<div class="switch%-box size%-picker">%s+<a href="(.-)" rel="(.-)"')
	if media_url == nil or image_dimension == nil then
		write_log("[error][imagesbase] Cant't find media_url or image_dimension. Invalid url format")
		return nil
	end
	
	filename = string.format("%s-%s(%s).jpg", filename, image_id, image_dimension)
	rc, headers = http.request{url = 'https://imagesbase.ru'..media_url, output_filename = filename}
	if rc ~= 0 then
		write_log("[error][imagesbase] "..http.error(rc))
		return false
	end
	if callback_function_on_success ~= nil then
		callback_function_on_success(string.format("%s %s; %s (%s bytes)", os.date(), url, filename, format_number(os.getfilesize(filename))))
	end
	write_log(string.format("[info][imagesbase] Success saving file '%s' (%s bytes)", filename, format_number(os.getfilesize(filename))))
	if os.info() == "Windows" then
		os.execute('move '..filename..' wallpaper')
	else
		os.execute('mv '..filename..' wallpaper')
	end
	return true
end

function verify_imagesbase(url)
	return url:match('https://imagesbase%.ru/%S+/%d+%-%S+') or url:match('http://imagesbase%.ru/%S+/%d+%-%S+')
end

-- Output :
--	true : on success
--	false : timeout
--	nil : invalid response and other fail status
function download_imagesbase_category(url, callback_function_write_log, callback_function_on_success)
	local rc, headers, content, title, filename
	local w, write_log, links, download_func, n_success, n_fail, n_unsupported
	
	if callback_function_write_log ~= nil then
		write_log = callback_function_write_log
	else
		write_log = my_write_log
	end
	
	write_log('[info][imagesbase] Process '..url)
	rc, headers, content = http.request(url)
	if rc ~= 0 then
		write_log("[error][imagesbase] "..http.error(rc))
		return false
	end
	
	-- Do processing in here
	for w in content:gmatch('<a class="screen%-link" href="(.-)" title') do
		download_imagesbase(w, callback_function_write_log, callback_function_on_success)
	end
	return true
end

function verify_imagesbase_category(url)
	return url:match('https://imagesbase%.ru/%S+/') or
	url:match('https://imagesbase%.ru/%S+/page/%d+') or
	url:match('^https://imagesbase%.ru%/?$')
end

function show_verified_imagesbase()
	return 
[[
https://imagesbase.ru/futurism/2258-koenigsegg-agera-vehicle-concept-design.html
https://imagesbase.ru/ero/4656-allstars-by-ura-pechen.html
https://imagesbase.ru/ero/6575-pyat-golyh-devushek-stoyat-zadom.html
https://imagesbase.ru/ero/page/101/
https://imagesbase.ru/ero/
]]
end

-------------------------------------------------------------------------------
--	Library Testing
-------------------------------------------------------------------------------
-- content = show_verified_imagesbase()
-- content = [[
-- https://imagesbase.ru/
-- ]]

-- local MAXTRY = 10
-- local done, try
-- login_imagesbase(IMAGESBASE_USER, IMAGESBASE_PASS)
-- for url in content:gmatch("[^\r\n]+") do
	-- if verify_imagesbase(url) then
		-- done = download_imagesbase(url)
		-- try = 1
		-- while ((try <= MAXTRY) and (done == false)) do
			-- my_write_log('Retry '..try)
			-- done = download_imagesbase(url)
			-- try = try + 1
		-- end
	-- elseif verify_imagesbase_category(url) then
		-- done = download_imagesbase_category(url)
	-- else
		-- my_write_log('[error][imagesbase] invalid URL')
	-- end
-- end

-------------------------------------------------------------------------------
--	Library Interface
-------------------------------------------------------------------------------
return {
	download_category = download_imagesbase_category,
	verify_category = verify_imagesbase_category,	
	download = download_imagesbase,
	verified = show_verified_imagesbase,
	verify = verify_imagesbase
}