<<<<<<< HEAD
-- Lua Script : Gist Basic Operation in gist.github.com : read, create, upload, update, delete
-- Using modified Lua 5.1 https://drive.google.com/file/d/1imqMbflxEEc8OsTCJoHiuMufdAfJTNSg/view?usp=sharing
-- Dhani.Novan@gmail.com 21:17 25 July 2020

require('strict')
require('common')

local GITHUB_USER = "dhaninovan"
local GITHUB_TOKEN = "f46c53ce8bda7deca9496ae3d58ccc8285714c32"
local MAXTIMEOUT = 30

local function escape_str(s)
	local in_char  = {'\\', '"', '/', '\b', '\f', '\n', '\r', '\t'}
	local out_char = {'\\', '"', '/',  'b',  'f',  'n',  'r',  't'}

	for i, c in ipairs(in_char) do
		s = s:gsub(c, '\\' .. out_char[i])
	end
	return s
end

local function write_log(data)
	my_write_log(data)
end

-- input : URL
-- 		https://gist.github.com/dhaninovan/19611e27b450185cd15241035b5b2110
-- 		https://gist.github.com/dhaninovan/19611e27b450185cd15241035b5b2110/raw/c5716b82cacfb263cb4ee0f5cdf84a9912f35af6/success.log
-- output : string of content, return nil if fail
function read_gist(url)
	local rc, content, result
	
	result = string.match(url, 'https://gist.github.com/%w+/%w+')
	if result == nil then
		write_log("[error][read_gist] invalid GIST URL. Format: https://gist.github.com/user/gistid")
		return nil
	end
	
	if string.match(url, '/raw/') == nil then url = result..'/raw/' end
	rc, content = http.get_url(url..'?t='..os.date('%H%M%S'))
	if rc ~= 0 then
		write_log("[error][read_gist] "..http.error(rc))
		return nil
	end
	return content
end

-- input : filename, content, description : string
-- output : string of status response, return nil if error
function create_public_gist(filename, content, description)
	local action_url, action_form, rc, response
 
	if filename == nil then return nil end
	if content == nil then content = "" end
	if description == nil then description = "" end
	
	http.set_conf(http.OPT_HTTPAUTH, http.AUTH_BASIC)
	http.set_conf(http.OPT_USERPWD, GITHUB_USER..":"..GITHUB_TOKEN)
	action_url = 'https://api.github.com/gists'
	action_form = string.format('{"description": "%s","public": true,"files": {"%s": {"content": "%s"}}}', description, filename, escape_str(content))
	rc, response = http.post_form(action_url, action_form)
	 if rc ~= 0 then
		write_log("[error][create_public_gist] "..http.error(rc))
		return nil
	end
	return response
end

-- input : filename, *content, *description : string	* => optional
-- output : string of status response, return nil if error
function create_secret_gist(filename, content, description)
	local action_url, action_form, rc, response
 
	if filename == nil then return nil end
	if content == nil then content = "" end
	if description == nil then description = "" end
	
	http.set_conf(http.OPT_HTTPAUTH, http.AUTH_BASIC)
	http.set_conf(http.OPT_USERPWD, GITHUB_USER..":"..GITHUB_TOKEN)
	action_url = 'https://api.github.com/gists'
	action_form = string.format('{"description": "%s","public": false,"files": {"%s": {"content": "%s"}}}', description, filename, escape_str(content))
	rc, response = http.post_form(action_url, action_form)
	 if rc ~= 0 then
		write_log("[error][create_secret_gist] "..http.error(rc))
		return nil
	end
	return response
end

-- input : filename, content, description : string
-- output : string of status response, return nil if error
function upload_public_gist(filename, description)
	local content, action_url, action_form, rc, response
 
	if filename == nil then return nil end
	if description == nil then description = "" end
	content = load_file(filename)
	if content == nil then return nil end
	
	http.set_conf(http.OPT_HTTPAUTH, http.AUTH_BASIC)
	http.set_conf(http.OPT_USERPWD, GITHUB_USER..":"..GITHUB_TOKEN)
	action_url = 'https://api.github.com/gists'
	action_form = string.format('{"description": "%s","public": true,"files": {"%s": {"content": "%s"}}}', description, filename, escape_str(content))
	rc, response = http.post_form(action_url, action_form)
	 if rc ~= 0 then
		write_log("[error][upload_public_gist] "..http.error(rc))
		return nil
	end
	return response
end

-- input : filename, *content, *description : string	* => optional
-- output : string of status response, return nil if error
function upload_secret_gist(filename, description)
	local content, action_url, action_form, rc, response
 
	if filename == nil then return nil end
	if description == nil then description = "" end
	content = load_file(filename)
	if content == nil then return nil end
	
	http.set_conf(http.OPT_HTTPAUTH, http.AUTH_BASIC)
	http.set_conf(http.OPT_USERPWD, GITHUB_USER..":"..GITHUB_TOKEN)
	action_url = 'https://api.github.com/gists'
	action_form = string.format('{"description": "%s","public": false,"files": {"%s": {"content": "%s"}}}', description, filename, escape_str(content))
	rc, response = http.post_form(action_url, action_form)
	 if rc ~= 0 then
		write_log("[error][upload_secret_gist] "..http.error(rc))
		return nil
	end
	return response
end

-- input : gist_id, filename, content, description : string
-- output : string of status response, return nil if error
function update_gist(gist_id, filename, content, description)
	local action_url, action_form, rc, response
 
	if gist_id == nil then return nil end
	if filename == nil then return nil end
	if content == nil then content = "" end
	if description == nil then description = "" end
	
	if #content == 0 then
		content = load_file(filename)
		if content == nil then content = "" end
	end
	
	http.set_conf(http.OPT_CUSTOMREQUEST, "PATCH")
	http.set_conf(http.OPT_HTTPAUTH, http.AUTH_BASIC)
	http.set_conf(http.OPT_USERPWD, GITHUB_USER..":"..GITHUB_TOKEN)
	action_url = 'https://api.github.com/gists/'..gist_id
	action_form = string.format('{"description": "%s","files": {"%s": {"content": "%s"}}}', description, filename, escape_str(content))
	rc, response = http.post_form(action_url, action_form)
	http.set_conf(http.OPT_CUSTOMREQUEST, nil)
	 if rc ~= 0 then
		write_log("[error][update_gist] "..http.error(rc))
		return nil
	end
	return response
end

function delete_gist(gist_id)
	local action_url, rc, response
 
	if gist_id == nil then return nil end
	
	http.set_conf(http.OPT_CUSTOMREQUEST, "DELETE")
	http.set_conf(http.OPT_HTTPAUTH, http.AUTH_BASIC)
	http.set_conf(http.OPT_USERPWD, GITHUB_USER..":"..GITHUB_TOKEN)
	action_url = 'https://api.github.com/gists/'..gist_id
	rc, response = http.post_form(action_url, "")
	http.set_conf(http.OPT_CUSTOMREQUEST, nil)
	 if rc ~= 0 then
		write_log("[error][delete_gist] "..http.error(rc))
		return nil
	end
	return response
end

return {
	read = read_gist,
	create_public = create_public_gist,
	create_secret = create_secret_gist,
	upload_public = upload_public_gist,
	upload_secret = upload_secret_gist,
	update = update_gist,
	delete = delete_gist
}
=======
-- Lua Script : Gist Basic Operation in gist.github.com : read, create, upload, update, delete
-- Using modified Lua 5.1 https://drive.google.com/file/d/1imqMbflxEEc8OsTCJoHiuMufdAfJTNSg/view?usp=sharing
-- Dhani.Novan@gmail.com 21:17 25 July 2020

local GITHUB_USER = "dhaninovan"
local GITHUB_TOKEN = "f46c53ce8bda7deca9496ae3d58ccc8285714c32"
local MAXTIMEOUT = 30

local function escape_str(s)
	local in_char  = {'\\', '"', '/', '\b', '\f', '\n', '\r', '\t'}
	local out_char = {'\\', '"', '/',  'b',  'f',  'n',  'r',  't'}

	for i, c in ipairs(in_char) do
		s = s:gsub(c, '\\' .. out_char[i])
	end
	return s
end

local function write_log(data)
	print(os.date("%d/%m/%Y %H:%M:%S ")..data)
end

-- input : URL
-- 		https://gist.github.com/dhaninovan/19611e27b450185cd15241035b5b2110
-- 		https://gist.github.com/dhaninovan/19611e27b450185cd15241035b5b2110/raw/c5716b82cacfb263cb4ee0f5cdf84a9912f35af6/success.log
-- output : string of content, return nil if fail
function read_gist(url)
	local rc, content, result
	
	result = string.match(url, 'https://gist.github.com/%w+/%w+')
	if result == nil then
		write_log("[error][read_gist] invalid GIST URL. Format: https://gist.github.com/user/gistid")
		return nil
	end
	
	if string.match(url, '/raw/') == nil then url = result..'/raw/' end
	rc, content = http.get_url(url..'?t='..os.date('%H%M%S'))
	if rc ~= 0 then
		write_log("[error][read_gist] "..http.error(rc))
		return nil
	end
	return content
end

-- input : filename, content, description : string
-- output : string of status response, return nil if error
function create_public_gist(filename, content, description)
	local action_url, action_form, rc, response
 
	if filename == nil then return nil end
	if content == nil then content = "" end
	if description == nil then description = "" end
	
	http.set_conf(http.OPT_HTTPAUTH, http.AUTH_BASIC)
	http.set_conf(http.OPT_USERPWD, GITHUB_USER..":"..GITHUB_TOKEN)
	action_url = 'https://api.github.com/gists'
	action_form = string.format('{"description": "%s","public": true,"files": {"%s": {"content": "%s"}}}', description, filename, escape_str(content))
	rc, response = http.post_form(action_url, action_form)
	 if rc ~= 0 then
		write_log("[error][create_public_gist] "..http.error(rc))
		return nil
	end
	return response
end

-- input : filename, *content, *description : string	* => optional
-- output : string of status response, return nil if error
function create_secret_gist(filename, content, description)
	local action_url, action_form, rc, response
 
	if filename == nil then return nil end
	if content == nil then content = "" end
	if description == nil then description = "" end
	
	http.set_conf(http.OPT_HTTPAUTH, http.AUTH_BASIC)
	http.set_conf(http.OPT_USERPWD, GITHUB_USER..":"..GITHUB_TOKEN)
	action_url = 'https://api.github.com/gists'
	action_form = string.format('{"description": "%s","public": false,"files": {"%s": {"content": "%s"}}}', description, filename, escape_str(content))
	rc, response = http.post_form(action_url, action_form)
	 if rc ~= 0 then
		write_log("[error][create_secret_gist] "..http.error(rc))
		return nil
	end
	return response
end

-- input : filename, content, description : string
-- output : string of status response, return nil if error
function upload_public_gist(filename, description)
	local content, action_url, action_form, rc, response
 
	if filename == nil then return nil end
	if description == nil then description = "" end
	content = load_file(filename)
	if content == nil then return nil end
	
	http.set_conf(http.OPT_HTTPAUTH, http.AUTH_BASIC)
	http.set_conf(http.OPT_USERPWD, GITHUB_USER..":"..GITHUB_TOKEN)
	action_url = 'https://api.github.com/gists'
	action_form = string.format('{"description": "%s","public": true,"files": {"%s": {"content": "%s"}}}', description, filename, escape_str(content))
	rc, response = http.post_form(action_url, action_form)
	 if rc ~= 0 then
		write_log("[error][upload_public_gist] "..http.error(rc))
		return nil
	end
	return response
end

-- input : filename, *content, *description : string	* => optional
-- output : string of status response, return nil if error
function upload_secret_gist(filename, description)
	local content, action_url, action_form, rc, response
 
	if filename == nil then return nil end
	if description == nil then description = "" end
	content = load_file(filename)
	if content == nil then return nil end
	
	http.set_conf(http.OPT_HTTPAUTH, http.AUTH_BASIC)
	http.set_conf(http.OPT_USERPWD, GITHUB_USER..":"..GITHUB_TOKEN)
	action_url = 'https://api.github.com/gists'
	action_form = string.format('{"description": "%s","public": false,"files": {"%s": {"content": "%s"}}}', description, filename, escape_str(content))
	rc, response = http.post_form(action_url, action_form)
	 if rc ~= 0 then
		write_log("[error][upload_secret_gist] "..http.error(rc))
		return nil
	end
	return response
end

-- input : gist_id, filename, content, description : string
-- output : string of status response, return nil if error
function update_gist(gist_id, filename, content, description)
	local action_url, action_form, rc, response
 
	if gist_id == nil then return nil end
	if filename == nil then return nil end
	if content == nil then content = "" end
	if description == nil then description = "" end
	
	if #content == 0 then
		content = load_file(filename)
		if content == nil then content = "" end
	end
	
	http.set_conf(http.OPT_CUSTOMREQUEST, "PATCH")
	http.set_conf(http.OPT_HTTPAUTH, http.AUTH_BASIC)
	http.set_conf(http.OPT_USERPWD, GITHUB_USER..":"..GITHUB_TOKEN)
	action_url = 'https://api.github.com/gists/'..gist_id
	action_form = string.format('{"description": "%s","files": {"%s": {"content": "%s"}}}', description, filename, escape_str(content))
	rc, response = http.post_form(action_url, action_form)
	http.set_conf(http.OPT_CUSTOMREQUEST, nil)
	 if rc ~= 0 then
		write_log("[error][update_gist] "..http.error(rc))
		return nil
	end
	return response
end

function delete_gist(gist_id)
	local action_url, rc, response
 
	if gist_id == nil then return nil end
	
	http.set_conf(http.OPT_CUSTOMREQUEST, "DELETE")
	http.set_conf(http.OPT_HTTPAUTH, http.AUTH_BASIC)
	http.set_conf(http.OPT_USERPWD, GITHUB_USER..":"..GITHUB_TOKEN)
	action_url = 'https://api.github.com/gists/'..gist_id
	rc, response = http.post_form(action_url, "")
	http.set_conf(http.OPT_CUSTOMREQUEST, nil)
	 if rc ~= 0 then
		write_log("[error][delete_gist] "..http.error(rc))
		return nil
	end
	return response
end

return {
	read = read_gist,
	create_public = create_public_gist,
	create_secret = create_secret_gist,
	upload_public = upload_public_gist,
	upload_secret = upload_secret_gist,
	update = update_gist,
	delete = delete_gist
}
>>>>>>> 478ee0c630df3dd05f487792bf05114041b26aed
