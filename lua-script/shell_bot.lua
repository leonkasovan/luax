-- Lua script for serving shell command as telegram bot
-- Hotel Ibis Senen, 3 Juli 2021 ( Covid break )

local rc, headers, content, resp, fi, fo
local local_last_update_id

local TOKEN1 = '1082609389'
local TOKEN2 = 'AAFJ4OdO7KvWFG24zkzsX6povpOZnv1kU0M'
local API_TELEGRAM_BOT = 'https://api.telegram.org/bot'..TOKEN1..':'..TOKEN2..'/'
local MAXTRY = 10

local gist = dofile('github/gist.lua')

function shell_run(cmd)
	local fi, res
	print(cmd)
	res = ""
	fi = io.popen(cmd)
	if fi then
		res = fi:read("*a")
		fi:close()
	end
	
	return res
end

function add_download(url, desc)
	local list_of_urls = gist.read('https://gist.github.com/dhaninovan/c3f8927ba4c3d75c7d552ee06ca2335e')
	local try

	try = 1
	while ((list_of_urls == nil) and (try < MAXTRY)) do
		list_of_urls = gist.read('https://gist.github.com/dhaninovan/c3f8927ba4c3d75c7d552ee06ca2335e')
		try = try + 1
	end
	
	if list_of_urls == nil then return false end
	if desc then
		gist.update('c3f8927ba4c3d75c7d552ee06ca2335e', 'list_url.txt', string.format("%s\n\#%s\n%s", list_of_urls, desc, url))
	else
		gist.update('c3f8927ba4c3d75c7d552ee06ca2335e', 'list_url.txt', string.format("%s\n%s", list_of_urls, url))
	end
	
	return true
end

rc, headers, content = http.request(API_TELEGRAM_BOT..'getMe')
resp = json.decode(content)
if not resp.ok or resp == nil then
	print("Invalid response")
	return -1
end
print(os.date()..' Initializing '..resp.result.username..' as telegram Bot Server [done]')

fi = io.open("last_update.json", "r")
if fi ~= nil then
	content = fi:read("*a")
	fi:close()
	local_last_update_id = json.decode(content).last_update_id
else
	local_last_update_id = 0
end
print(os.date()..' Loading last_update_id = '..local_last_update_id..' [done]')

rc, headers, content = http.request(API_TELEGRAM_BOT..'getUpdates?offset='..(local_last_update_id+1))
resp = json.decode(content)
for i,v in pairs(resp.result) do
	if v.message then
		if v.message.text then
			print(string.format('%s New text message from %s_%s: %s', os.date(), v.message.from.first_name, v.message.from.last_name, v.message.text))
			if v.message.text:find('/show_log') then
				rc, headers, content = http.request(API_TELEGRAM_BOT..'sendMessage','chat_id='..v.message.chat.id..'&text='..http.escape(shell_run('tail -c 2000 multi_host_downloader/multi_host_downloader.log')))
			elseif v.message.text:find('/show_files') then
				rc, headers, content = http.request(API_TELEGRAM_BOT..'sendMessage','chat_id='..v.message.chat.id..'&text='..http.escape(shell_run('ls -rholt multi_host_downloader | tail -c 2000')))
			elseif v.message.text:find('/move_files') then
				rc, headers, content = http.request(API_TELEGRAM_BOT..'sendMessage','chat_id='..v.message.chat.id..'&text='..http.escape(shell_run('mv multi_host_downloader/*.mp4 /media/pi')))
			elseif v.message.text:find('/update_src') then
				rc, headers, content = http.request(API_TELEGRAM_BOT..'sendMessage','chat_id='..v.message.chat.id..'&text='..http.escape(shell_run('cd .. && git pull')))
			elseif v.message.text:find('/run_dl') then
				rc, headers, content = http.request(API_TELEGRAM_BOT..'sendMessage','chat_id='..v.message.chat.id..'&text='..http.escape(shell_run('cd multi_host_downloader && lua multi_host_downloader.lua')))
			elseif v.message.text:find('/view_process') then
				rc, headers, content = http.request(API_TELEGRAM_BOT..'sendMessage','chat_id='..v.message.chat.id..'&text='..http.escape(shell_run('ps -C lua --format stime,time,pid,cmd | tail -c 2000')))
			elseif v.message.text:find('^http.?://') then
				if add_download(v.message.text) then
					rc, headers, content = http.request(API_TELEGRAM_BOT..'sendMessage','chat_id='..v.message.chat.id..'&text=Success+adding+url')
				else
					rc, headers, content = http.request(API_TELEGRAM_BOT..'sendMessage','chat_id='..v.message.chat.id..'&text=Failed+adding+url')
				end
			else
				rc, headers, content = http.request(API_TELEGRAM_BOT..'sendMessage','chat_id='..v.message.chat.id..'&text='..http.escape(shell_run(v.message.text..' | tail -c 2000')))
			end
		elseif v.message.document then
			print(string.format('%s New document from %s_%s: %s', os.date(), v.message.from.first_name, v.message.from.last_name, v.message.document.file_name))
		end
	end
	local_last_update_id = v.update_id
end
if #resp.result > 0 then
	fo = io.open("last_update.json", "w+")
	fo:write(string.format('{"last_update_id":%d}', local_last_update_id))
	fo:close()
	print(os.date()..' Processing '..#resp.result..' message(s)')
	print(os.date()..' Writing last_update_id '..local_last_update_id..' [done]')
else
	print(os.date()..' Nothing new')
end
