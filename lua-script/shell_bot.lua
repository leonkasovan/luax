-- Lua script for serving shell command as telegram bot
-- Hotel Ibis Senen, 3 Juli 2021 ( Covid break )

local rc, headers, content, resp, fi, fo
local local_last_update_id

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

rc, headers, content = http.request('https://api.telegram.org/bot1082609389:AAE8TJPP_57Nqg-boKPOTuLz-U-vYg02CoY/getMe')
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

rc, headers, content = http.request('https://api.telegram.org/bot1082609389:AAE8TJPP_57Nqg-boKPOTuLz-U-vYg02CoY/getUpdates')
resp = json.decode(content)
for i,v in pairs(resp.result) do
	if v.update_id > local_last_update_id then
		rc, headers, content = http.request('https://api.telegram.org/bot1082609389:AAE8TJPP_57Nqg-boKPOTuLz-U-vYg02CoY/sendMessage?chat_id='..v.message.chat.id..'&text='..http.escape(shell_run(v.message.text)))
		print(string.format('%s New text message from %s_%s: %s', os.date(), v.message.from.first_name, v.message.from.last_name, v.message.text))
		local_last_update_id = v.update_id
	end
end

fo = io.open("last_update.json", "w+")
fo:write(string.format('{"last_update_id":%d}', local_last_update_id))
fo:close()
print(os.date()..' Writing last_update_id '..local_last_update_id..' [done]')

