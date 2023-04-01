#!/storage/usr/bin/luax
-- Luax script for searching cheat from gamehacking.org
-- dhani.novan@gmail.com, November 2022

-- /storage/roms/xxx = gamehacking.org/system/xxx
local SYSTEM_ID = {
["psx"] = "psx",
["snes"] = "snes",
["genesis"] = "gen",
["dreamcast"] = "dc",
["neogeo"] = "neo",
["gamegear"] = "gg",
["sega32x"] = "32x",
["segacd"] = "scd",
["saturn"] = "sat",
["mastersystem"] = "sms",
["gb"] = "gb",
["gba"] = "gba",
["gbc"] = "gbc",
["gamecube"] = "ngc",
["nds"] = "nds",
["n64"] = "n64",
["nes"] = "nes"
}

-- arg[1] = "/userdata/roms/psx"
-- arg[2] = "evil zone"
if #arg == 2 then
	local system, keyword, rc, headers, content, line
	system = arg[1]:match('roms/(.-)$')
	keyword = arg[2]:gsub("%s","%%20")
	rc, headers, content = http.request('https://gamehacking.org/system/'..SYSTEM_ID[system]..'/'..keyword)
	if rc ~= 0 then
		print("Error: "..http.error(rc), rc)
		return false
	end

	local result, result2, game_title, game_url, game_version--, game_serial, game_size, game_crc32, game_ncodes
	for line in content:gmatch("[^\r\n]+") do
		result = line:match('<th class="active" colspan="8">(.-)</th>')
		if result ~= nil then
			game_title = result
		end
		result, result2 = line:match('<td><a href="/game/(.-)">(.-)</a></td>')
		if result ~= nil then
			game_url = result
		end
		if result2 ~= nil then
			game_version = result2
			print(string.format("%s%s|%s", game_title, game_version, game_url))
		end
	end
	return true
elseif #arg == 1 then	-- arg[1] is game_id
	local rc, headers, content, system_id, game_title
	
	rc, headers, content = http.request('https://gamehacking.org/game/'..arg[1])
	if rc ~= 0 then
		print("Error: "..http.error(rc), rc)
		return false
	end
	system_id = content:match('name="sysID" value="(.-)" />')
	if system_id == nil then
		print('Not match sysID!')
		return false
	end
	game_title = content:match('org %| (.-)</title>')
	if game_title == nil then
		print('Not match game_title!')
		return false
	end
	rc, headers = http.request{ url = "https://gamehacking.org/inc/sub.exportCodes.php",
	formdata = "format=libretro&sysID="..system_id.."&gamID="..arg[1].."&download=true",
	output_filename = game_title..".cht"}
	if rc ~= 0 then
		print("Error: "..http.error(rc))
		return false
	end
	
	print(game_title..".cht")
	return true
else
	print(string.format("Searching or downloading cheat from gamehacking.org.\nUsage: \n\t#> %s [path] [keyword]", arg[0]))
	print(string.format("\t#> %s \"/storage/roms/psx\" \"evil zone\"", arg[0]))
	print(string.format("\t#> %s [game_id]", arg[0]))
	print(string.format("\t#> %s 88803", arg[0]))
	return true
end
