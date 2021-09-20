-- Lua 5.1.5.XL Script for downloading media from https://eropics.to/2019/01/06/cke18-rimi-hands-attack
-- Interpreter : luaX https://github.com/dhaninovan/luax/releases/download/v5.1.5.77/lua.exe
-- dhani.novan@gmail.com 31/12/2021, Rawamangun

dofile('../strict.lua')
dofile('../common.lua')

local UNSUPPORTED_FILENAME = 'unsupported_links.txt'
local imx = dofile('../imx/imx.lua')
local vipr = dofile('../vipr/vipr.lua')

function verify(url)
	if imx.verify(url) then
		return imx.download
	elseif vipr.verify(url) then
		return vipr.download
	else
		return nil
	end
end

function append_file(fname, data)
	local fo
	
	fo = io.open(fname,"a")
	if fo ~= nil then
		fo:write(data..'\n')
		fo:close()
	else
		fo = io.open(fname,"w")
		fo:write(data..'\n')
		fo:close()
	end
end

function my_write_log(data)
	print(os.date("%d/%m/%Y %H:%M:%S ")..data)
end

-- Output :
--	true : on success
--	false : timeout
--	nil : invalid response and other fail status
function download_eropics(url, callback_function_write_log, callback_function_on_success)
	local rc, headers, content, title, filename
	local write_log, links, download_func, n_success, n_fail, n_unsupported
	
	if callback_function_write_log ~= nil then
		write_log = callback_function_write_log
	else
		write_log = my_write_log
	end
	
	write_log('[info][eropics] Process '..url)
	rc, headers, content = http.request(url)
	if rc ~= 0 then
		write_log("[error][eropics] "..http.error(rc))
		return false
	end
	-- Do processing in here
	n_success = 0
	n_fail = 0
	n_unsupported = 0
	content = content:match('<div class="entry%-content">(.-)</div>')
	links = http.collect_link(content, url)
	for i,v in pairs(links) do
		-- print(i,v)
		download_func = verify(v)
		if download_func then
			if download_func(v, callback_function_write_log, callback_function_on_success) then
				n_success = n_success + 1
			else
				n_fail = n_fail + 1
			end
		else
			append_file(UNSUPPORTED_FILENAME, v)
			n_unsupported = n_unsupported + 1
		end
	end
	
	title = url:match('/%d%d/%d%d/(%S-)$')
	if n_success > 0 then
		if title == nil then
			title = "no-title"
		end
		print('Moving to '..title)
		os.execute('mkdir '..title)
		if os.info() == "Windows" then
			os.execute('move *.jpg '..title)
		else
			os.execute('mv *.jpg '..title)
		end
	end
	write_log('[info][eropics] Total success: '..n_success..' (check in folder '..title..')')
	write_log('[info][eropics] Total fail: '..n_fail)
	write_log('[info][eropics] Total unsupported links: '..n_unsupported..' (check in file '..UNSUPPORTED_FILENAME..')')
	if callback_function_on_success ~= nil then
		callback_function_on_success(string.format("%s %s (%s images)", os.date(), url, n_success))
	end
	return true
end

function verify_eropics(url)
	return url:match('https://eropics%.to/%d+/%d+/%d+/%S+')
end

function show_verified_eropics()
	return 
[[
https://eropics.to/2019/01/06/cke18-rimi-hands-attack
]]
end

-------------------------------------------------------------------------------
--	Library Testing
-------------------------------------------------------------------------------
-- content = [[
-- https://eropics.to/2021/09/08/thisisglamour-lycia-cutie-pie-tease-x155-september-7-2021
-- ]]

-- local MAXTRY = 10
-- local done, try
-- for url in content:gmatch("[^\r\n]+") do
	-- if verify_eropics(url) then
		-- done = download_eropics(url)
		-- try = 1
		-- while ((try <= MAXTRY) and (done == false)) do
			-- my_write_log('Retry '..try)
			-- done = download_eropics(url)
			-- try = try + 1
		-- end
	-- else
		-- my_write_log('[error][eropics] invalid URL')
	-- end
-- end

-------------------------------------------------------------------------------
--	Library Interface
-------------------------------------------------------------------------------
return {
	download = download_eropics,
	verified = show_verified_eropics,
	verify = verify_eropics
}