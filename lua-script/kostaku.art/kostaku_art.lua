#!/usr/bin/luax
-- Lua 5.1.5.XL Script for downloading media from https://kostaku.art
-- Interpreter : luaX https://github.com/dhaninovan/luax/releases/download/v5.1.5.77/lua.exe
-- dhani.novan@gmail.com 5:27 18 June 2023 Cempaku Putih

-- dofile('../strict.lua')
-- dofile('../common.lua')

function my_write_log(data)
	print(os.date("%d/%m/%Y %H:%M:%S ")..data)
end

-- Output :
--	true : on success
--	false : timeout
--	nil : invalid response and other fail status
function download_kostaku(url, callback_function_write_log, callback_function_on_success, target_directory)
	local rc, headers, content, title, filename
	local write_log, nsuccess
	
	if callback_function_write_log ~= nil then
		write_log = callback_function_write_log
	else
		write_log = my_write_log
	end
	
	write_log('[info][kostaku] Process '..url)
	rc, headers, content = http.request(url)
	if rc ~= 0 then
		write_log("[error][kostaku] "..http.error(rc))
		return false
	end
	
	-- Do processing in here
	nsuccess = 0
	http.set_conf(http.OPT_NOPROGRESS, false)
	for w in content:gmatch('<p><img loading="lazy" src="(.-)"') do
		print(w)
		if target_directory ~= nil then
			rc, headers = http.request{url = w, output_filename = target_directory..http.resource_name(w)}
		else
			rc, headers = http.request{url = w, output_filename = http.resource_name(w)}
		end
		if rc ~= 0 then
			print("Error: "..http.error(rc), rc)
		else
			nsuccess = nsuccess + 1
		end
	end
	http.set_conf(http.OPT_NOPROGRESS, true)
	
	-- if callback_function_on_success ~= nil then
		-- callback_function_on_success(string.format("%s %s; %s (%s bytes)", os.date(), url, filename, format_number(os.getfilesize(filename))))
	-- end
	write_log(string.format("[info][kostaku] Success saved %d image", nsuccess))
	return true
end

function verify_kostaku(url)
	return url:match('https://kostaku%.art/%w') or url:match('http://kostaku%.art/%w')
end

function show_verified_kostaku()
	return 
[[
https://kostaku.art/3463
]]
end

-------------------------------------------------------------------------------
--	Library Testing
-------------------------------------------------------------------------------
-- content = show_verified_kostaku()

-- local MAXTRY = 10
-- local done, try
-- for url in content:gmatch("[^\r\n]+") do
	-- if verify_kostaku(url) then
		-- done = download_kostaku(url)
		-- try = 1
		-- while ((try <= MAXTRY) and (done == false)) do
			-- my_write_log('Retry '..try)
			-- done = download_kostaku(url)
			-- try = try + 1
		-- end
	-- else
		-- my_write_log('[error][kostaku] invalid URL')
	-- end
-- end

-------------------------------------------------------------------------------
--	Library Interface
-------------------------------------------------------------------------------
-- return {
	-- download = download_kostaku,
	-- verified = show_verified_kostaku,
	-- verify = verify_kostaku
-- }

-------------------------------------------------------------------------------
--	Main
-------------------------------------------------------------------------------
local MAXTRY = 3
local done, try
local rc, headers, content
local DOWNLOADED_FILENAME = 'kostaku_done.txt'
local url = 'https://kostaku.art/'
local url = 'https://kostaku.art/tag/313'
-- local target_directory = '/userdata/library/'
local target_directory = '/userdata/screenshots/'
-- local target_directory = 'C:\\Users\\Personal Komputer\\Pictures\\Saved Pictures\\'
local links

local function is_infile(data, fname)
	local fi, content
	
	fi = io.open(fname, "r")
	if fi ~= nil then
		content = fi:read("*a")
		fi:close()
		if content:find(data, 1, true) ~= nil then
			return true
		end
	end
	fi = gzio.open(fname..'.gz', "r")
	if fi ~= nil then
		content = fi:read("*a")
		fi:close()
		if content:find(data, 1, true) ~= nil then
			return true
		end
	end
	return false
end

local function append_file(data, fname)
	local fo
	
	fo = io.open(fname, "a")
	if fo ~= nil then
		fo:write(data..'\n')
		fo:close()
	else
		fo = io.open(fname,"w")
		fo:write(data..'\n')
		fo:close()
	end
end

rc, headers, content = http.request(url)
if rc == 0 then
	links = http.collect_link(content, url)
	for i,v in pairs(links) do
		if v:match('art/%d%d%d%d') ~= nil then
			if is_infile(v, DOWNLOADED_FILENAME) == false then
				done = download_kostaku(v, nil, nil, target_directory)
				try = 1
				while ((try <= MAXTRY) and (done == false)) do
					my_write_log('Retry '..try)
					done = download_kostaku(v, nil, nil, target_directory)
					try = try + 1
				end
				
				if done then
					append_file(v, DOWNLOADED_FILENAME)
				end
			end
		end
	end
end
return true