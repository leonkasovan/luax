-- Lua 5.1.5.XL Script for downloading file from https://games-database.com
-- Interpreter : luaX https://github.com/dhaninovan/luax/releases/download/v5.1.5.77/lua.exe
-- dhani.novan@gmail.com 20/05/2021, Rawamangun

dofile('../strict.lua')
dofile('../common.lua')

local MAXTIMEOUT = 3600	-- set max timeout 60 minutes

function my_write_log(data)
	print(os.date("%d/%m/%Y %H:%M:%S ")..data)
end

-- Output :
--	true : on success
--	false : timeout
--	nil : invalid response and other fail status
function download_games_db(url, callback_function_write_log, callback_function_on_success)
	local rc, headers, content, title, filename
	local write_log, media_url, wait_time
	
	if callback_function_write_log ~= nil then
		write_log = callback_function_write_log
	else
		write_log = my_write_log
	end
	
	write_log('[info][games_db] Process '..url)
	rc, headers, content = http.request(url)
	if rc ~= 0 then
		write_log("[error][games_db] "..http.error(rc))
		return false
	end
		-- Do processing in here
	wait_time = string.match(content, 'var seconds = (%d+)%;')
	media_url = string.match(content, "free' href='(.-)'")
	filename = string.match(content, 'text"></i> (.-)</div>')
	if media_url == nil or filename == nil or wait_time == nil then write_log('[error][games_db] invalid response. (1)') save_file(content, 'games_db_invalid_content.htm') return nil end
	wait_time = tonumber(wait_time) + 1
	
	if os.info() == "Linux" then
		os.execute('sleep '..wait_time)
	else
		os.execute('timeout '..wait_time)
	end
	
	http.set_conf(http.OPT_TIMEOUT, MAXTIMEOUT)
	rc, headers = http.request{url = media_url, output_filename = filename}
	if rc ~= 0 then
		write_log("[error][games_db] "..http.error(rc))
		return false
	end
	
	if callback_function_on_success ~= nil then
		callback_function_on_success(string.format("%s %s; %s (%s bytes)", os.date(), url, filename, format_number(os.getfilesize(filename))))
	end
	write_log(string.format("[info][games_db] Success saving file '%s' (%s bytes)", filename, format_number(os.getfilesize(filename))))
	return true
end

function verify_games_db(url)
	return url:match('https://games%-database%.com/%S+') or url:match('http://games%-database%.com/%S+')
end

function show_verified_games_db()
	return 
[[
https://games-database.com/aab
]]
end

-------------------------------------------------------------------------------
--	Library Testing
-------------------------------------------------------------------------------
-- Source : https://repack-games.com/
content = [[
https://games-database.com/aab
]]

local MAXTRY = 10
local done, try
for url in content:gmatch("[^\r\n]+") do
	if verify_games_db(url) then
		done = download_games_db(url)
		try = 1
		while ((try <= MAXTRY) and (done == false)) do
			my_write_log('Retry '..try)
			done = download_games_db(url)
			try = try + 1
		end
	else
		my_write_log('[error][games_db] invalid URL')
	end
end

-------------------------------------------------------------------------------
--	Library Interface
-------------------------------------------------------------------------------
return {
	download = download_games_db,
	verified = show_verified_games_db,
	verify = verify_games_db
}