-- Lua script for serving shell command as telegram bot
-- Hotel Ibis Senen, 3 Juli 2021 ( Covid break )

local rc, headers, content, resp, fi, fo
local local_last_update_id

local TOKEN1 = '1082609389'
local TOKEN2 = 'AAFJ4OdO7KvWFG24zkzsX6povpOZnv1kU0M'
local API_TELEGRAM_BOT = 'https://api.telegram.org/bot'..TOKEN1..':'..TOKEN2..'/'

function shell_run(cmd)
	local fi, res
	
	res = ""
	fi = io.popen(cmd)
	if fi then
		res = fi:read("*a")
		fi:close()
	end
	
	return res
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
	print(string.format('%s New text message from %s_%s: %s', os.date(), v.message.from.first_name, v.message.from.last_name, v.message.text))
	if v.message.text:find('/show_log') then
		rc, headers, content = http.request(API_TELEGRAM_BOT..'sendMessage?chat_id='..v.message.chat.id..'&text='..http.escape(shell_run('cat multi_host_downloader/multi_host_downloader.log')))
	elseif v.message.text:find('/show_files') then
		rc, headers, content = http.request(API_TELEGRAM_BOT..'sendMessage?chat_id='..v.message.chat.id..'&text='..http.escape(shell_run('ls -l multi_host_downloader')))
	else
		rc, headers, content = http.request(API_TELEGRAM_BOT..'sendMessage?chat_id='..v.message.chat.id..'&text='..http.escape(shell_run(v.message.text)))
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
