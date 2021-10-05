

-- content = 'https://eropics.to/2019/01/06/cke18-rimi-hands-attack'
-- print(content)
-- print(content:match('/%d%d/%d%d/(%S-)$'))

function load_file(filename)
	local fi, content

	fi = io.open(filename, "r")
	if fi == nil then
		print("[error] Load file "..filename)
		return nil
	end
	content = fi:read("*a")
	fi:close()
	return content
end
content = load_file('test.txt')
-- print(content:match('%d:(%d+) lua multi_host_downloader%.lua'))

local duration = 0
for hh,mm in content:gmatch('(%d+):(%d+) lua multi_host_downloader%.lua') do
	print(hh, mm)
	duration = duration + tonumber(hh)*60 + tonumber(mm)*60
end

print('Duration: '..duration)