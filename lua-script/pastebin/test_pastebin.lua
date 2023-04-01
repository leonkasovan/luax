local pastebin = dofile('pastebin.lua')

-- for i,v in pairs(pastebin.list_as_table()) do
	-- print(i,v[1], v[2], v[3])
-- end
print(pastebin.list())
print("-------------------------")
-- pastebin.append_by_title('New url 2', 'success_log')
pastebin.update_by_title('#List success_log', 'success_log')
print(pastebin.list())

-- for i,v in pairs(pastebin.list_as_table()) do
	-- print(i,v[1], v[2], v[3])
-- end
