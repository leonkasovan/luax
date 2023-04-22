local pastebin = dofile('pastebin.lua')

-- for i,v in pairs(pastebin.list_as_table()) do
	-- print(i,v[1], v[2], v[3])
-- end
-- print(pastebin.list())
-- print("-------------------------")
-- pastebin.append_by_title('New url 2', 'success_log')
-- for i,v in pairs(pastebin.list_as_table()) do
	-- print(i,v[1], v[2], v[3])
-- end
-- pastebin.update_by_title('#List success_log', 'success_log')
-- print(pastebin.list())

pastebin.append_by_title('https://www.vidio.com/live/204-sctv', 'success_log')
pastebin.append_by_title('https://www.vidio.com/live/204-rcti', 'success_log')
pastebin.append_by_title('https://www.vidio.com/live/204-indosiar', 'success_log')