-- test gist github library

local gist = dofile('../lua-script/github/gist.lua')

print('Create Public Gist 1')
response = gist.create_secret('file1.txt', 'This content\\nline2\\nline3\\nline4\\n')
if response then
	gist1 = json.decode(response)
	table.foreach(gist1, print)
end
print('Create Public Gist 1 done')

--print('Create Public Gist 2, with description')
--response = gist.create_public('file2.txt', 'This content\\nline2\\nline3\\nline4\\nline5', 'This is my custom desc')
--if response then
--	gist2 = json.decode(response)
--	table.foreach(gist2, print)
--end

print('Update Gist, existing file')
response = gist.update(gist1.id, 'file1.txt', 'This is NEW content\\nline2\\nline3\\nline4\\nline5', 'This is my new desc')
if response then
	res = json.decode(response)
	table.foreach(res, print)
end
