-- Lua 5.1.5.XL Script for grabbing media from https://girlygirlpic.com
-- Interpreter : luaX https://github.com/dhaninovan/luax/releases/download/v5.1.5.77/lua.exe
-- dhani.novan@gmail.com 09/06/2021, Rawamangun

dofile('../strict.lua')
dofile('../common.lua')

local function is_done(url)
	local fi, content
	
	fi = io.open('girlygirlpic_done.txt', "r")
	if fi ~= nil then
		content = fi:read("*a")
		fi:close()
		if content:find(url, 1, true) ~= nil then
			return true
		end
	end
	fi = gzio.open('girlygirlpic_done.txt.gz', "r")
	if fi ~= nil then
		content = fi:read("*a")
		fi:close()
		if content:find(url, 1, true) ~= nil then
			return true
		end
	end
	return false
end

local function append_done(url)
	local fo
	
	fo = io.open('girlygirlpic_done.txt', "a")
	if fo ~= nil then
		fo:write(url..'\n')
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
function download_girlygirlpic(url, callback_function_write_log, callback_function_on_success)
	local rc, headers, content, title, filename, gallery_id
	local write_log, media_url, links, nsaved, ntry, log_filename
	
	if callback_function_write_log ~= nil then
		write_log = callback_function_write_log
	else
		write_log = my_write_log
	end
	
	write_log('[info][girlygirlpic] Process '..url)
	gallery_id = url:match('girlygirlpic%.com/a/(.-)$')
	rc, headers, content = http.request{
	url = 'https://en.girlygirlpic.com/ax/',
	formdata = '{"album_id":"'..gallery_id..'"}',
	headers = { "Connection: Keep-Alive", "X-Requested-With: XMLHttpRequest", "Content-Type: application/json", "Origin: https://en.girlygirlpic.com"}}
	if rc ~= 0 then
		write_log("[error][girlygirlpic] "..http.error(rc))
		return false
	end
	-- save_file(content, 'girlygirlpic3.htm')
	title = content:match("<li><span>(.-)</span></ul>")
	title = title:gsub('%[.-%]', '')
	title = title:gsub('%W','_')
	print(title)
	filename = title:sub(1,15)
	
	-- Do processing in here
	links = http.collect_link(content, url)
	nsaved = 0
	for i,v in pairs(links) do
		if v:match('^https://img%.girlygirlpic%.com') then
			if is_done(v) == false then
				ntry = 0
				repeat
					if ntry > 0 then print(string.format('Retry %d: %s', ntry, v)) end
					rc, headers = http.request{url = v, output_filename = filename..nsaved..'.jpg'}
					ntry = ntry + 1
				until rc == 0 or ntry > 3
				if rc ~= 0 then
					print("[error] "..http.error(rc), rc)
				else
					append_done(v)
					nsaved = nsaved + 1
					print(nsaved..'. [saved]'..v)
				end
			else
				print('[skipped]'..v)
			end
		end
	end
	
	if nsaved > 0 then
		if title ~= nil then
			print('Moving to '..title)
			os.execute('mkdir '..title)
			os.execute('move *.jpg '..title)
		end
		append_done(url)
		write_log('[info][girlygirlpic] Gallery ['..title..'] total image saved : '..nsaved)
	else
		write_log('[info][girlygirlpic] Gallery ['..title..'] skipped')
	end
	-- archieving log for done url
	log_filename = 'girlygirlpic_done.txt'
	if os.getfilesize(log_filename) > 500000 then
		fo = gzio.open(log_filename..'.gz.new','w')
		fi = gzio.open(log_filename..'.gz','r')
		if fi ~= nil then
			for line in fi:lines() do
				fo:write(line..'\n')
			end
			fi:close()
			os.execute('del '..log_filename..'.gz')
		end
		fi = io.open(log_filename, 'r')
		fo:write(fi:read('*a'))
		fi:close()
		fo:close()
		os.execute('del '..log_filename)
		os.execute('ren '..log_filename..'.gz.new '..log_filename..'.gz')
	end
	
	if callback_function_on_success ~= nil then
		callback_function_on_success(string.format("%s %s; %s (%s images)", os.date(), url, title, nsaved))
	end
	return true
end

-- Output :
--	true : on success
--	false : timeout
--	nil : invalid response and other fail status
function download_girlygirlpic_agency(url, callback_function_write_log, callback_function_on_success, page)
	local rc, headers, content, gallery_id
	local write_log, links
	
	if callback_function_write_log ~= nil then
		write_log = callback_function_write_log
	else
		write_log = my_write_log
	end
	
	gallery_id = url:match('girlygirlpic%.com/c/(.-)$')
	
	if page == nil then
		write_log('[info][girlygirlpic] Process Agency '..url)
		rc, headers, content = http.request{
		url = 'https://en.girlygirlpic.com/cx/',
		formdata = '{"company_id":"'..gallery_id..'"}',
		headers = { "Connection: Keep-Alive", "X-Requested-With: XMLHttpRequest", "Content-Type: application/json", "Origin: https://en.girlygirlpic.com"}}
		if rc ~= 0 then	write_log("[error][girlygirlpic] "..http.error(rc)) return false end
		links = http.collect_link(content, url)
	else
		write_log('[info][girlygirlpic] Process Agency '..url..' Page '..page)
		rc, headers, content = http.request{
		url = 'https://en.girlygirlpic.com/api/getcompanyalbumslist',
		formdata = '{"action":"load_infinite_content","next_params":"paged='..page..'&posts_per_page=10&post_status=publish&category__in=0","layout_type":"v3","template_type":"","page_id":"pid407","random_index":0,"model_id":"","company_id":"'..gallery_id..'","tag_id":"","country_id":"","type_tag":"Company","search_keys_tag":""}',
		headers = { "Accept: application/json, text/javascript, */*; q=0.01", "Connection: Keep-Alive", "X-Requested-With: XMLHttpRequest", "Content-Type: application/json", "Origin: https://en.girlygirlpic.com"}}
		if rc ~= 0 then	write_log("[error][girlygirlpic] "..http.error(rc)) return false end
		links = http.collect_link(json.decode(content).new_posts, url)
	end
	
	-- Do processing in here	
	for i,v in pairs(links) do
		if v:match('^https://en%.girlygirlpic%.com/a/.......$') then
			download_girlygirlpic(v)
		end
	end

	-- if callback_function_on_success ~= nil then
		-- callback_function_on_success(string.format("%s %s; %s (%s images)", os.date(), url, title, nsaved))
	-- end
	return true
end

-- Output :
--	true : on success
--	false : timeout
--	nil : invalid response and other fail status
function download_girlygirlpic_tag(url, callback_function_write_log, callback_function_on_success, page)
	local rc, headers, content, gallery_id
	local write_log, links
	
	if callback_function_write_log ~= nil then
		write_log = callback_function_write_log
	else
		write_log = my_write_log
	end
	
	gallery_id = url:match('girlygirlpic%.com/t/(.-)$')
	
	if page == nil then
		write_log('[info][girlygirlpic] Process Tag '..url)
		rc, headers, content = http.request{
		url = 'https://en.girlygirlpic.com/tx/',
		formdata = '{"tag_id":"'..gallery_id..'"}',
		headers = { "Connection: Keep-Alive", "X-Requested-With: XMLHttpRequest", "Content-Type: application/json", "Origin: https://en.girlygirlpic.com"}}
		if rc ~= 0 then	write_log("[error][girlygirlpic] "..http.error(rc)) return false end
		links = http.collect_link(content, url)
	else
		write_log('[info][girlygirlpic] Process Tag '..url..' Page '..page)
		rc, headers, content = http.request{
		url = 'https://en.girlygirlpic.com/api/gettagalbumslist',
		formdata = '{"action":"load_infinite_content","next_params":"paged='..page..'&posts_per_page=10&post_status=publish&category__in=0","layout_type":"v3","template_type":"","page_id":"pid407","random_index":0,"model_id":"","company_id":"","tag_id":"'..gallery_id..'","country_id":"","type_tag":"Company","search_keys_tag":""}',
		headers = { "Accept: application/json, text/javascript, */*; q=0.01", "Connection: Keep-Alive", "X-Requested-With: XMLHttpRequest", "Content-Type: application/json", "Origin: https://en.girlygirlpic.com", "Sec-Fetch-Site: same-origin", "Sec-Fetch-Mode: cors", "Sec-Fetch-Dest: empty"}}
		if rc ~= 0 then	write_log("[error][girlygirlpic] "..http.error(rc)) return false end
		links = http.collect_link(json.decode(content).new_posts, url)
	end
	
	-- Do processing in here	
	for i,v in pairs(links) do
		if v:match('^https://en%.girlygirlpic%.com/a/.......$') then
			download_girlygirlpic(v)
		end
	end

	-- if callback_function_on_success ~= nil then
		-- callback_function_on_success(string.format("%s %s; %s (%s images)", os.date(), url, title, nsaved))
	-- end
	return true
end

-- Output :
--	true : on success
--	false : timeout
--	nil : invalid response and other fail status
function download_girlygirlpic_model(url, callback_function_write_log, callback_function_on_success, page)
	local rc, headers, content, gallery_id
	local write_log, links
	
	if callback_function_write_log ~= nil then
		write_log = callback_function_write_log
	else
		write_log = my_write_log
	end
	
	gallery_id = url:match('girlygirlpic%.com/m/(.-)$')
	
	if page == nil then
		write_log('[info][girlygirlpic] Process Model '..url)
		rc, headers, content = http.request{
		url = 'https://en.girlygirlpic.com/mx/',
		formdata = '{"model_Id":"'..gallery_id..'"}',
		headers = { "Connection: Keep-Alive", "X-Requested-With: XMLHttpRequest", "Content-Type: application/json", "Origin: https://en.girlygirlpic.com"}}
		if rc ~= 0 then	write_log("[error][girlygirlpic] "..http.error(rc)) return false end
		links = http.collect_link(content, url)
	else
		write_log('[info][girlygirlpic] Process Model '..url..' Page '..page)
		rc, headers, content = http.request{
		url = 'https://en.girlygirlpic.com/api/getmodelalbumslist',
		formdata = '{"action":"load_infinite_content","next_params":"paged='..page..'&posts_per_page=10&post_status=publish&category__in=0","layout_type":"v3","template_type":"","page_id":"pid407","random_index":0,"model_id":"'..gallery_id..'","company_id":"","tag_id":"","country_id":"","type_tag":"Company","search_keys_tag":""}',
		headers = { "Accept: application/json, text/javascript, */*; q=0.01", "Connection: Keep-Alive", "X-Requested-With: XMLHttpRequest", "Content-Type: application/json", "Origin: https://en.girlygirlpic.com"}}
		if rc ~= 0 then	write_log("[error][girlygirlpic] "..http.error(rc)) return false end
		links = http.collect_link(json.decode(content).new_posts, url)
	end
	
	-- Do processing in here	
	for i,v in pairs(links) do
		if v:match('^https://en%.girlygirlpic%.com/a/.......$') then
			download_girlygirlpic(v)
		end
	end

	-- if callback_function_on_success ~= nil then
		-- callback_function_on_success(string.format("%s %s; %s (%s images)", os.date(), url, title, nsaved))
	-- end
	return true
end

-- Output :
--	true : on success
--	false : timeout
--	nil : invalid response and other fail status
function download_girlygirlpic_country(url, callback_function_write_log, callback_function_on_success, page)
	local rc, headers, content, gallery_id
	local write_log, links
	
	if callback_function_write_log ~= nil then
		write_log = callback_function_write_log
	else
		write_log = my_write_log
	end
	
	gallery_id = url:match('girlygirlpic%.com/l/(.-)$')
	
	if page == nil then
		write_log('[info][girlygirlpic] Process Country '..url)
		rc, headers, content = http.request{
		url = 'https://en.girlygirlpic.com/lx/',
		formdata = '{"country_id":"'..gallery_id..'"}',
		headers = { "Connection: Keep-Alive", "X-Requested-With: XMLHttpRequest", "Content-Type: application/json", "Origin: https://en.girlygirlpic.com"}}
		if rc ~= 0 then	write_log("[error][girlygirlpic] "..http.error(rc)) return false end
		links = http.collect_link(content, url)
	else
		write_log('[info][girlygirlpic] Process Country '..url..' Page '..page)
		rc, headers, content = http.request{
		url = 'https://en.girlygirlpic.com/api/getcountryalbumslist',
		formdata = '{"action":"load_infinite_content","next_params":"paged='..page..'&posts_per_page=10&post_status=publish&category__in=0","layout_type":"v3","template_type":"","page_id":"pid407","random_index":0,"model_id":"","company_id":"","tag_id":"","country_id":"'..gallery_id..'","type_tag":"Company","search_keys_tag":""}',
		headers = { "Accept: application/json, text/javascript, */*; q=0.01", "Connection: Keep-Alive", "X-Requested-With: XMLHttpRequest", "Content-Type: application/json", "Origin: https://en.girlygirlpic.com"}}
		if rc ~= 0 then	write_log("[error][girlygirlpic] "..http.error(rc)) return false end
		links = http.collect_link(json.decode(content).new_posts, url)
	end
	
	-- Do processing in here	
	for i,v in pairs(links) do
		if v:match('^https://en%.girlygirlpic%.com/a/.......$') then
			download_girlygirlpic(v)
		end
	end

	-- if callback_function_on_success ~= nil then
		-- callback_function_on_success(string.format("%s %s; %s (%s images)", os.date(), url, title, nsaved))
	-- end
	return true
end

function verify_girlygirlpic(url)
	return url:match('https://en%.girlygirlpic%.com/a/%w') or url:match('http://en%.girlygirlpic%.com/a/%w')
end

function verify_girlygirlpic_country(url)
	return url:match('https://en%.girlygirlpic%.com/l/%w') or url:match('http://en%.girlygirlpic%.com/l/%w')
end

function verify_girlygirlpic_agency(url)
	return url:match('https://en%.girlygirlpic%.com/c/%w') or url:match('http://en%.girlygirlpic%.com/c/%w')
end

function verify_girlygirlpic_tag(url)
	return url:match('https://en%.girlygirlpic%.com/t/%w') or url:match('http://en%.girlygirlpic%.com/t/%w')
end

function verify_girlygirlpic_model(url)
	return url:match('https://en%.girlygirlpic%.com/m/%w') or url:match('http://en%.girlygirlpic%.com/m/%w')
end

function show_verified_girlygirlpic()
	return 
[[
https://en.girlygirlpic.com/l/6imhhs2
https://en.girlygirlpic.com/t/6xdch0x
https://en.girlygirlpic.com/c/2cef8ad
https://en.girlygirlpic.com/m/7cywcgv
https://en.girlygirlpic.com/a/79djz5k
]]
end

-------------------------------------------------------------------------------
--	Library Testing
-------------------------------------------------------------------------------
-- content = [[
-- https://en.girlygirlpic.com/t/6xdch0x
-- ]]

-- for url in content:gmatch("[^\r\n]+") do
	-- if verify_girlygirlpic(url) then
		-- download_girlygirlpic(url)
	-- elseif verify_girlygirlpic_agency(url) then
		-- download_girlygirlpic_agency(url)
	-- elseif verify_girlygirlpic_tag(url) then
		-- download_girlygirlpic_tag(url)
	-- elseif verify_girlygirlpic_model(url) then
		-- download_girlygirlpic_model(url)
	-- elseif verify_girlygirlpic_country(url) then
		-- download_girlygirlpic_country(url)
	-- else
		-- my_write_log('[error][girlygirlpic] invalid URL')
	-- end
-- end

-- download_girlygirlpic_tag('https://en.girlygirlpic.com/t/6xdch0x')	-- Page 0
-- download_girlygirlpic_tag('https://en.girlygirlpic.com/t/6xdch0x', nil, nil, 1)	-- Page 1
-- download_girlygirlpic_tag('https://en.girlygirlpic.com/t/6xdch0x', nil, nil, 2)	-- Page 2
-- download_girlygirlpic_tag('https://en.girlygirlpic.com/t/6xdch0x', nil, nil, 8)	-- Page 3

-------------------------------------------------------------------------------
--	Library Interface
-------------------------------------------------------------------------------
return {
	download = download_girlygirlpic,
	verified = show_verified_girlygirlpic,
	verify = verify_girlygirlpic,
	verify_agency = verify_girlygirlpic_agency,
	download_agency = download_girlygirlpic_agency,
	verify_tag = verify_girlygirlpic_tag,
	download_tag = download_girlygirlpic_tag,
	verify_model = verify_girlygirlpic_model,
	download_model = download_girlygirlpic_model,
	verify_country = verify_girlygirlpic_country,
	download_country = download_girlygirlpic_country
}
