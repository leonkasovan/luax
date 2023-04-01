-- Lua Script : Basic Operation in Pastebin.com : Read Paste, New Paste, Update Paste
-- Using modified Lua 5.1

--local DEBUG = true	-- write all log to a file (LOG_FILE)
local DEBUG = false	-- write all log to console output
local LOG_FILE = "luaPastebin.log"
local USERNAME = "leonkasovan"
local USERPASS = "rikadanR1"
local MAXTIMEOUT = 30
local api_user_key = nil

--os.execute("del "..LOG_FILE)
function write_log(data)
	local fo
	if DEBUG then 
		fo = io.open(LOG_FILE, "a")
		if fo == nil then
			print("Can not open "..LOG_FILE)
			return nil
		end
		fo:write(table.concat{os.date(), " ", data, "\n"})
		fo:close()
		return true
	else
		print(data)
		return true
	end
end

function save_file(content, filename)
	local fo
	
	fo = io.open(filename, "w")
	if fo == nil then
		write_log('[error] Save file '..filename)
		return false
	end
	fo:write(content)
	fo:close()
	return true
end

function load_file(filename)
	local fi, content

	fi = io.open(filename, "r")
	if fi == nil then
		write_log("[error] Load file "..filename)
		return nil
	end
	content = fi:read("*a")
	fi:close()
	return content
end

--input 1: paste_id(string)
--input 2: login(bool,optional) 
	-- value : true = for access private paste
	-- value : false = for access public/unlisted paste (default)
--output : content of paste(string), return nil if fail
function read_paste(paste_id, login)
	local rc, content

	if login then	-- login for access private/unlisted paste
		http.set_conf(http.OPT_TIMEOUT, 30)
		rc, content = http.post_form('https://pastebin.com/login', 'submit_hidden=submit_hidden&submit=Login&user_name='..USERNAME..'&user_password='..USERPASS)
		if rc ~= 0 then
			write_log("[error] Login: "..http.error(rc))
			return nil
		end
	end
	http.set_conf(http.OPT_TIMEOUT, 30)
	rc, content = http.get_url("https://pastebin.com/raw/"..paste_id)
	if rc ~= 0 then
		write_log("[error] Reading paste "..paste_id..": "..http.error(rc))
		return nil
	end
	
	return content
end

--input 1: content(string)
--input 2: paste name(string, optional) default = MyPaste 31/12/20 23:59:59
--input 3: paste_private(string, optional) 0 = Public (default), 1 = Unlisted, 2 = Private
--output : new paste id(string), return nil if fail
function new_paste(content, paste_name, paste_private)
	local rc
	paste_name = paste_name or 'MyPaste '..os.date()
	paste_private = paste_private or '0'
	
	-- Authentification
	if api_user_key == nil then
		http.set_conf(http.OPT_TIMEOUT, 30)
		rc, api_user_key = http.post_form('https://pastebin.com/api/api_login.php', 'api_dev_key=1b9f95b79f59af3f51bb793540445838&api_user_name='..USERNAME..'&api_user_password='..USERPASS)
		if rc ~= 0 then
			write_log("[error] Login: "..http.error(rc))
			return nil
		end
	end
	
	-- New Paste
	http.set_conf(http.OPT_TIMEOUT, 60)
	rc, paste_id = http.post_form('https://pastebin.com/api/api_post.php', table.concat({
	'api_dev_key=1b9f95b79f59af3f51bb793540445838',
	'api_option=paste',
	'api_paste_private='..paste_private,	-- 0 = Public, 1 = Unlisted, 2 = Private
	'api_paste_expire_date=N',	-- N = Never, 1Y = 1 Year, 1M = 1 Month, 1D = 1 Day
	'api_user_key='..api_user_key,
	'api_paste_code='..http.escape(content),
	'api_paste_name='..http.escape(paste_name)
	},'&'))
	if rc ~= 0 then
		write_log("[error] New Paste: "..http.error(rc))
		return nil
	end
	return paste_id
end

--input 1: content(string)
--input 2: paste name(string, optional) default = MyPaste 31/12/20 23:59:59
--output : true if success, return nil if fail
function update_paste(paste_id, content, new_paste_name)
	local action_form, rc, headers, res, api_user_key, csrf_frontend
	local prev_paste_name, prev_paste_format, prev_paste_status
	
	http.set_conf(http.OPT_TIMEOUT, MAXTIMEOUT)
	http.set_conf(http.OPT_USERAGENT, 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:103.0) Gecko/20100101 Firefox/103.0')
	http.set_conf(http.OPT_COOKIEFILE, "cookies.txt")
	-- Request Edit Paste Form
	http.set_conf(http.OPT_TIMEOUT, MAXTIMEOUT)
	rc, res = http.get_url("https://pastebin.com/edit/"..paste_id)
	if rc ~= 0 then
		write_log("[error] Paste Edit: "..http.error(rc))
		return nil
	end
	
	-- Extract Token
	csrf_frontend = string.match(res, '<meta name="csrf%-token" content="(.-)">')
	if csrf_frontend == nil then
		write_log("[error] Invalid Response. Can not find csrf_frontend in Paste ID "..paste_id)
		save_file(res, 'invalid_response.htm')
		return nil
	end
	
	parent_id = string.match(res, '<input type="hidden" id="postform%-parent_id" class="form%-control" name="PostForm%[parent%_id%]" value="(.-)">')
	if parent_id == nil then parent_id = "" end
	
	prev_paste_format = string.match(res, '<select id="postform%-format" class="form%-control".-<option value="(%d-)" selected>.-<div class="form%-group field%-postform%-expiration">')
	-- Default value for Paste Format 1 = None
	if prev_paste_format == nil then prev_paste_format = "1" end
	print("prev_paste_format", prev_paste_format)
	prev_paste_status = string.match(res, '<select id="postform%-status" class="form%-control".-<option value="(%d-)" selected>')
	-- Default value for Paste Exposure 2 = Private
	if prev_paste_status == nil then prev_paste_status = "2" end
	print("prev_paste_status", prev_paste_status)
	
	if new_paste_name == nil then
		prev_paste_name = string.match(res, '<input type="text" id="postform%-name".-value="(.-)"')
		if prev_paste_name == nil then prev_paste_name = 'MyPaste '..os.date() end
		new_paste_name = prev_paste_name
	end

	-- Post Update Paste Form
	http.set_conf(http.OPT_TIMEOUT, MAXTIMEOUT)
	rc = http.post_form("https://pastebin.com/edit/"..paste_id, 
		'_csrf-frontend='..csrf_frontend..
		'&PostForm[text]='..http.escape(content)..
		'&PostForm[parent_id]='..parent_id..
		'&PostForm[format]='..prev_paste_format..
		'&PostForm[expiration]=PREV'..
		'&PostForm[status]='..prev_paste_status..
		'&PostForm[name]='..http.escape(new_paste_name))
	if rc ~= 0 then
		write_log("[error] Post Update Paste: "..http.error(rc))
		return nil
	end

	return true
end

function delete_paste(key)
	local rc, res
	
	if key == nil or key == "" then
		write_log("[error delete] Key is empty")
		return nil
	end
	
	write_log("[info delete_paste] Key: "..key)
	-- Authentification
	if api_user_key == nil then
		http.set_conf(http.OPT_TIMEOUT, 30)
		rc, api_user_key = http.post_form('https://pastebin.com/api/api_login.php', 'api_dev_key=1b9f95b79f59af3f51bb793540445838&api_user_name='..USERNAME..'&api_user_password='..USERPASS)
		if rc ~= 0 then
			write_log("[error] Login: "..http.error(rc))
			return nil
		end
	end
	
	-- Delete Paste
	http.set_conf(http.OPT_TIMEOUT, 60)
	rc, res = http.post_form('https://pastebin.com/api/api_post.php', table.concat({
	'api_dev_key=1b9f95b79f59af3f51bb793540445838',
	'api_option=delete',
	'api_user_key='..api_user_key,
	'api_paste_key='..key
	},'&'))
	if rc ~= 0 then
		write_log("[error] List Paste: "..http.error(rc))
		return nil
	end
	write_log("[info delete] "..res)
	return res
end

function list_paste(limit)
	local rc, list_paste
	
	if limit == nil then
		limit = '1000'
	end
	
	-- Authentification
	if api_user_key == nil then
		http.set_conf(http.OPT_TIMEOUT, 30)
		rc, api_user_key = http.post_form('https://pastebin.com/api/api_login.php', 'api_dev_key=1b9f95b79f59af3f51bb793540445838&api_user_name='..USERNAME..'&api_user_password='..USERPASS)
		if rc ~= 0 then
			write_log("[error] Login: "..http.error(rc))
			return nil
		end
	end
	
	-- Get List Paste
	http.set_conf(http.OPT_TIMEOUT, 60)
	rc, list_paste = http.post_form('https://pastebin.com/api/api_post.php', table.concat({
	'api_dev_key=1b9f95b79f59af3f51bb793540445838',
	'api_option=list',
	'api_user_key='..api_user_key,
	'api_results_limit='..limit
	},'&'))
	if rc ~= 0 then
		write_log("[error] List Paste: "..http.error(rc))
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

function append_paste_by_title(new_content, paste_title)
	local res, old_content
	
	if #paste_title == 0 then
		write_log("[error] Paste Title is empty")
		return nil
	end
	
	res = nil
	write_log("[info append_paste_by_title] searching title: "..paste_title)
	for i,v in pairs(list_paste_as_table()) do
		if v[3] == paste_title then
			old_content = read_paste(v[1])
			if old_content == nil then 
				res = new_paste(new_content, paste_title, '1')	-- 0 = Public, 1 = Unlisted, 2 = Private
			else
				res = new_paste(old_content..'\n'..new_content, paste_title, '1')	-- 0 = Public, 1 = Unlisted, 2 = Private
			end
			write_log("[info append_paste_by_title] found title: "..paste_title)
			write_log("[info append_paste_by_title] delete old title: "..v[3])
			delete_paste(v[1])
			break
		end
	end
	write_log("[info append_paste_by_title] new key: "..res)
	return res
end

function update_paste_by_title(new_content, paste_title)
	local res
	
	if #paste_title == 0 then
		write_log("[error] Paste Title is empty")
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
	update_by_title = update_paste_by_title,
	append_by_title = append_paste_by_title,
	update = update_paste
}

-- Test Case Function Pastebin

--Case : Public Paste 
--result = read_paste('rJVY34Ng')
--if result then
--	write_log(result)
--end

--Case : Unlisted Paste 
--result = read_paste('ZQhh3kzE')
--if result then
--	write_log(result)
--end

--Case: Private Paste
--result = read_paste('JnezduvT', true)
--if result then
--	write_log(result)
--end

--Case: Invalid Paste 
--result = read_paste('xxxxxxxx')	
--if result then
--	write_log(result)
--end

--Case: simplest new paste
--url_paste_id = new_paste('This is my simplest new paste\nSecond Line')
--if url_paste_id then
--	write_log('Click '..url_paste_id)
--else
--	write_log('New Paste Fail')
--end

--Case: simple new paste with a name
--url_paste_id = new_paste('This is my simple new paste\nSecond Line','My Simple Paste')
--if url_paste_id then
--	write_log('Click '..url_paste_id)
--else
--	write_log('New Paste Fail')
--end

--Case: New Paste from a file
--filename = 'pastebin_download.lua'
--url_paste_id = new_paste(load_file(filename),filename)
--if url_paste_id then
--	write_log('Click '..url_paste_id)
--else
--	write_log('New Paste Fail')
--end

-- Case: update content
--id = 'mxd45wyi'
--if update_paste(id, 'Kita update lagi\nBaris satu\nBaris dua\nBaris tiga\nBaris empat\nBaris lima') then
--	write_log('Update Paste success. Click https://pastebin.com/'..id)
--else
--	write_log('Update Paste Fail')
--end

-- Case: update content and rename
-- id = 'Db4MUNJg'
-- if update_paste(id, 'rem hourly_action_lua.bat\ndel *.bat\ndir * O:A','BAT destroyer') then
	-- write_log('Update Paste success. Click https://pastebin.com/'..id)
-- else
	-- write_log('Update Paste Fail')
-- end


--if not DEBUG then os.execute("pause") end

-- GET /edit/Db4MUNJg HTTP/2
-- Host: pastebin.com
-- User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:103.0) Gecko/20100101 Firefox/103.0
-- Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8
-- Accept-Language: en-US,en;q=0.5
-- Accept-Encoding: gzip, deflate, br
-- Connection: keep-alive
-- Referer: https://pastebin.com/Db4MUNJg
-- Cookie: _csrf-frontend=2e9d9c96eef813c2f205489aaeb89b624bb15b8260835546fbf94169a06381e6a%3A2%3A%7Bi%3A0%3Bs%3A14%3A%22_csrf-frontend%22%3Bi%3A1%3Bs%3A32%3A%22Cn8lzjAxE6gKP1D35zbtKL9FuvwVNThX%22%3B%7D; l2c_2_pg=true; l2c_1=true; cf_clearance=pzzwI4QR9DVwjW_a61RTa8RNxu.JvOxvLzO3ZTt0EIk-1659262495-0-150; pastebin-frontend=1897840c958f22eb5a62e5a6f20676de; _identity-frontend=67cfb5cf3957d28cfa2149ed08cdba3a48ae2752b7e419a2cb8ffc0a9d8fc305a%3A2%3A%7Bi%3A0%3Bs%3A18%3A%22_identity-frontend%22%3Bi%3A1%3Bs%3A53%3A%22%5B6029595%2C%22Z0jaqABM8QAKVF51dFWwdZFiDGobQuW7%22%2C15552000%5D%22%3B%7D
-- Upgrade-Insecure-Requests: 1
-- Sec-Fetch-Dest: document
-- Sec-Fetch-Mode: navigate
-- Sec-Fetch-Site: same-origin
-- Sec-Fetch-User: ?1
-- TE: trailers

-- POST /edit/Db4MUNJg HTTP/2
-- Host: pastebin.com
-- User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:103.0) Gecko/20100101 Firefox/103.0
-- Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8
-- Accept-Language: en-US,en;q=0.5
-- Accept-Encoding: gzip, deflate, br
-- Content-Type: multipart/form-data; boundary=---------------------------33297592724860868572492733630
-- Content-Length: 1432
-- Origin: https://pastebin.com
-- Connection: keep-alive
-- Referer: https://pastebin.com/edit/Db4MUNJg
-- Cookie: _csrf-frontend=2e9d9c96eef813c2f205489aaeb89b624bb15b8260835546fbf94169a06381e6a%3A2%3A%7Bi%3A0%3Bs%3A14%3A%22_csrf-frontend%22%3Bi%3A1%3Bs%3A32%3A%22Cn8lzjAxE6gKP1D35zbtKL9FuvwVNThX%22%3B%7D; l2c_2_pg=true; l2c_1=true; cf_clearance=pzzwI4QR9DVwjW_a61RTa8RNxu.JvOxvLzO3ZTt0EIk-1659262495-0-150; pastebin-frontend=1897840c958f22eb5a62e5a6f20676de; _identity-frontend=67cfb5cf3957d28cfa2149ed08cdba3a48ae2752b7e419a2cb8ffc0a9d8fc305a%3A2%3A%7Bi%3A0%3Bs%3A18%3A%22_identity-frontend%22%3Bi%3A1%3Bs%3A53%3A%22%5B6029595%2C%22Z0jaqABM8QAKVF51dFWwdZFiDGobQuW7%22%2C15552000%5D%22%3B%7D
-- Upgrade-Insecure-Requests: 1
-- Sec-Fetch-Dest: document
-- Sec-Fetch-Mode: navigate
-- Sec-Fetch-Site: same-origin
-- Sec-Fetch-User: ?1
-- TE: trailers

---------------------------33297592724860868572492733630
-- Content-Disposition: form-data; name="_csrf-frontend"

-- RiiECBeTPW-z4mWQU3gQ1fYSgK6RfsxDMzm9AC9thsAFRrxkbfl8F_bUAtsDSVTmw2ji2toy9QVGT8pWYTnumA==
---------------------------33297592724860868572492733630
-- Content-Disposition: form-data; name="PostForm[text]"

-- Setelah diedit
-- mejadi 2 line saja

---------------------------33297592724860868572492733630
-- Content-Disposition: form-data; name="PostForm[format]"

-- 1
---------------------------33297592724860868572492733630
-- Content-Disposition: form-data; name="PostForm[expiration]"

-- PREV
---------------------------33297592724860868572492733630
-- Content-Disposition: form-data; name="PostForm[status]"

-- 1
---------------------------33297592724860868572492733630
-- Content-Disposition: form-data; name="PostForm[folder_key]"


---------------------------33297592724860868572492733630
-- Content-Disposition: form-data; name="PostForm[folder_name]"


---------------------------33297592724860868572492733630
-- Content-Disposition: form-data; name="PostForm[is_password_enabled]"

-- 0
---------------------------33297592724860868572492733630
-- Content-Disposition: form-data; name="PostForm[is_burn]"

-- 0
---------------------------33297592724860868572492733630
-- Content-Disposition: form-data; name="PostForm[name]"

-- Testing
---------------------------33297592724860868572492733630--
