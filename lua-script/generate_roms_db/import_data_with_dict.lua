-- Source HTM : 
-- https://archive.org/download/MAME_2003-Plus_Reference_Set_2018/roms/
-- https://archive.org/download/MAME_2003-Plus_Reference_Set_2018/MAME%202003-Plus%20-%202018-12-31.xml

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

local t = {}
content = load_file('MAME 2003-Plus - 2018-12-31.xml')
for w1,w2 in content:gmatch('<game name="(.-)".-<description>(.-)</description>') do
	t[w1] = w2
end

content = load_file('mame2003plus.htm')
for w1,w2,w3 in content:gmatch('<td><a href="(.-)">.-</td>.-<td>(.-)</td>.-<td>(.-)</td>') do
	if #w3 > 1 then
		w2 = w1:gsub("%.zip","")
		if t[w2] ~= nil then
			print(w2.."|"..t[w2].."|"..w3)
		else
			print(w2.."||"..w3)
		end
	end
end
