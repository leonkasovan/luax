-- Lua Script : Basic Operation in Pastebin.com : Read Paste, New Paste, Update Paste
-- Using modified Lua 5.1

--local DEBUG = true	-- write all log to a file (LOG_FILE)
dofile('../strict.lua')
dofile('../common.lua')

local DEBUG = false	-- write all log to console output
local LOG_FILE = "luaPastebin.log"
local USERNAME = "leonkasovan"
local USERPASS = "rikadanR1"
local MAXTIMEOUT = 30
local api_user_key = nil

local function write_log(data)
	if DEBUG then 
		local fo
		fo = io.open(LOG_FILE, "a")
		if fo == nil then
			print("Can not open "..LOG_FILE)
			return nil
		end
		fo:write(table.concat{os.date(), " ", data, "\n"})
		fo:close()
		return true
	else
		print(os.date("%d/%m/%Y %H:%M:%S ")..data)
		return true
	end
end

--input 1: paste_id(string)
--input 2: login(bool,optional) 
	-- value : true = for access private paste
	-- value : false = for access public/unlisted paste (default)
--output : content of paste(string), return nil if fail
function read_paste(paste_id, login)
	local rc, content, headers

	http.set_conf(http.OPT_TIMEOUT, MAXTIMEOUT)
	if login then	-- login for access private/unlisted paste
		rc, headers, content = http.request('https://pastebin.com/login', 'submit_hidden=submit_hidden&submit=Login&user_name='..USERNAME..'&user_password='..USERPASS)
		if rc ~= 0 then
			write_log("[ERROR | pastebin | read_paste] Login: "..http.error(rc))
			return nil
		end
	end
	rc, headers, content = http.request("https://pastebin.com/raw/"..paste_id)
	if rc ~= 0 then
		write_log("[ERROR | pastebin | read_paste] "..paste_id..": "..http.error(rc))
		return nil
	end
	
	return content
end

--input 1: content(string)
--input 2: paste name(string, optional) default = MyPaste 31/12/20 23:59:59
--input 3: paste_private(string, optional) 0 = Public (default), 1 = Unlisted, 2 = Private
--output : new paste id(string), return nil if fail
function new_paste(content, paste_name, paste_private)
	local rc, paste_id, headers
	paste_name = paste_name or 'MyPaste '..os.date()
	paste_private = paste_private or '0'
	
	http.set_conf(http.OPT_TIMEOUT, MAXTIMEOUT)
	-- Authentification
	if api_user_key == nil then
		rc, headers, api_user_key = http.request('https://pastebin.com/api/api_login.php', 'api_dev_key=1b9f95b79f59af3f51bb793540445838&api_user_name='..USERNAME..'&api_user_password='..USERPASS)
		if rc ~= 0 then
			write_log("[ERROR | pastebin | new_paste] Login: "..http.error(rc))
			return nil
		end
	end
	
	-- New Paste
	rc, headers, paste_id = http.request('https://pastebin.com/api/api_post.php', table.concat({
	'api_dev_key=1b9f95b79f59af3f51bb793540445838',
	'api_option=paste',
	'api_paste_private='..paste_private,	-- 0 = Public, 1 = Unlisted, 2 = Private
	'api_paste_expire_date=N',	-- N = Never, 1Y = 1 Year, 1M = 1 Month, 1D = 1 Day
	'api_user_key='..api_user_key,
	'api_paste_code='..http.escape(content),
	'api_paste_name='..http.escape(paste_name)
	},'&'))
	if rc ~= 0 then
		write_log("[ERROR | pastebin | new_paste] "..http.error(rc))
		return nil
	end
	
	if #paste_id ~= 29 then
		write_log("[ERROR | pastebin | new_paste] "..paste_id)
	end
	return paste_id
end

function delete_paste(key)
	local rc, res, headers
	
	if key == nil or key == "" then
		write_log("[error delete] Key is empty")
		return nil
	end
	
	http.set_conf(http.OPT_TIMEOUT, MAXTIMEOUT)
	-- Authentification
	if api_user_key == nil then
		rc, headers, api_user_key = http.request('https://pastebin.com/api/api_login.php', 'api_dev_key=1b9f95b79f59af3f51bb793540445838&api_user_name='..USERNAME..'&api_user_password='..USERPASS)
		if rc ~= 0 then
			write_log("[ERROR | pastebin | delete_paste] Login: "..http.error(rc))
			return nil
		end
	end
	
	-- Delete Paste
	rc, headers, res = http.request('https://pastebin.com/api/api_post.php', table.concat({
	'api_dev_key=1b9f95b79f59af3f51bb793540445838',
	'api_option=delete',
	'api_user_key='..api_user_key,
	'api_paste_key='..key
	},'&'))
	if rc ~= 0 then
		write_log("[ERROR | pastebin | delete_paste] "..http.error(rc))
		return nil
	end
	
	if res ~= "Paste Removed" then
		write_log("[ERROR | pastebin | delete_paste] "..res)
	end
	return res
end

function list_paste(limit)
	local rc, list_paste, headers
	
	if limit == nil then
		limit = '1000'
	end
	http.set_conf(http.OPT_TIMEOUT, MAXTIMEOUT)
	
	-- Authentification
	if api_user_key == nil then
		rc, headers, api_user_key = http.request('https://pastebin.com/api/api_login.php', 'api_dev_key=1b9f95b79f59af3f51bb793540445838&api_user_name='..USERNAME..'&api_user_password='..USERPASS)
		if rc ~= 0 then
			write_log("[ERROR | pastebin | list_paste] Login: "..http.error(rc))
			return nil
		end
	end
	
	-- Get List Paste
	rc, headers, list_paste = http.request('https://pastebin.com/api/api_post.php', table.concat({
	'api_dev_key=1b9f95b79f59af3f51bb793540445838',
	'api_option=list',
	'api_user_key='..api_user_key,
	'api_results_limit='..limit
	},'&'))
	if rc ~= 0 then
		write_log("[ERROR | pastebin | list_paste] "..http.error(rc))
		return nil
	end
	return list_paste
end

-- input: limit max of paste result
-- output: table of paste data (1. paste_key, 2. paste_date, 3. paste_title)
function list_paste_as_table(limit)
	local content, t_paste
	
	content = list_paste(limit)
	if content == nil then
		return nil
	end
	
	t_paste = {}
	for paste_key,paste_date,paste_title in content:gmatch('<paste_key>(.-)</paste_key>.-<paste_date>(.-)</paste_date>.-<paste_title>(.-)</paste_title>') do
		t_paste[#t_paste + 1] = {paste_key, paste_date, paste_title}
	end
	
	return t_paste
end

function read_paste_by_title(paste_title)
	local content
	
	if #paste_title == 0 then
		write_log("[ERROR | pastebin | read_paste_by_title] Paste Title is empty")
		return nil
	end
	
	content = nil
	for i,v in pairs(list_paste_as_table()) do
		if v[3] == paste_title then
			content = read_paste(v[1])
			break
		end
	end
	return content
end

function append_paste_by_title(new_content, paste_title)
	local res, old_content
	
	if #paste_title == 0 then
		write_log("[ERROR | pastebin | append_paste_by_title] Paste Title is empty")
		return nil
	end
	
	res = nil
	for i,v in pairs(list_paste_as_table()) do
		if v[3] == paste_title then
			old_content = read_paste(v[1])
			if old_content == nil then
				res = new_paste(new_content, paste_title, '1')	-- 0 = Public, 1 = Unlisted, 2 = Private
			else
				res = new_paste(old_content..'\n'..new_content, paste_title, '1')	-- 0 = Public, 1 = Unlisted, 2 = Private
			end
			delete_paste(v[1])
			break
		end
	end
	return res
end

function update_paste_by_title(new_content, paste_title)
	local res
	
	if #paste_title == 0 then
		write_log("[ERROR | pastebin | update_paste_by_title] Paste Title is empty")
		return nil
	end
	
	res = nil
	for i,v in pairs(list_paste_as_table()) do
		if v[3] == paste_title then
			res = new_paste(new_content, paste_title, '1')	-- 0 = Public, 1 = Unlisted, 2 = Private
			delete_paste(v[1])
			break
		end
	end
	return res
end

return {
	read = read_paste,
	new = new_paste,
	delete = delete_paste,
	list = list_paste,
	list_as_table = list_paste_as_table,
	read_by_title = read_paste_by_title,
	update_by_title = update_paste_by_title,
	append_by_title = append_paste_by_title
}
