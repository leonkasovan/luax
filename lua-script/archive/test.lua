dofile('../common.lua')
dofile('../strict.lua')

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

-- Gamelist Result: 4761
-- Result created db: 30968
local content = load_file('mame2015.xml')
local no = 0
local game_id,game_title,game_year,game_publisher,game_player
for game_content in content:gmatch('<game name.-</game>') do
	game_id = game_content:match('game name="(.-)"')
	game_title = game_content:match('<description>(.-)</description>')
	game_year = game_content:match('<year>(.-)</year>') or '19xx'
	game_publisher = game_content:match('<manufacturer>(.-)</manufacturer>')
	game_player = game_content:match('players="(.-)"')
	runnable = game_content:find('runnable', 1, true)
	if runnable == nil then
		if game_id == nil or game_title == nil or game_year == nil or game_publisher == nil or game_player == nil then
			print(no, game_content:sub(1,200))
		end
		-- game_title = game_title:gsub("&amp;", "&")
		-- game_publisher = game_publisher:gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&amp;", "&")
		no = no + 1
	else
		-- skip
	end
end
print(no)