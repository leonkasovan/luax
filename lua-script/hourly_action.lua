-- Lua Script : Update log in gist.github.com
-- Using modified Lua 5.1 https://drive.google.com/file/d/1imqMbflxEEc8OsTCJoHiuMufdAfJTNSg/view?usp=sharing
-- Install in crontab : 0 * * * * cd /home/pi/shared/luax/lua-script && lua hourly_action.lua

local LOG_FILE = "multi_host_downloader/multi_host_downloader.log"

function load_file(filename)
	local fi, content

	fi = io.open(filename, "r")
	if fi == nil then
		print("[error] Load file "..filename)
		return ""
	end
	content = fi:read("*a")
	fi:close()
	return filename..':\n'..content..'\n\n'
end

function strip_html(filename)
	local fi, content

	fi = io.open(filename, "r")
	if fi == nil then
		print("[error] Load file "..filename)
		return ""
	end
	content = fi:read("*a")
	fi:close()
	return filename..':\n'..content:gsub("<style.->.-</style>",""):gsub("<script.->.-</script>",""):gsub("<!%-%-.-%-%->",""):gsub("<.->",""):gsub("%s+"," ")..'\n\n'
end

if os.info() == "Windows" then
	gist = require('github\\gist')
	os.execute('dir /A:-D /O:D > files.txt')	
else
	gist = dofile('github/gist.lua')
	os.execute("ls -lt multi_host_downloader > files.txt")
end

tcontent = {}
table.insert(tcontent, string.format("Time:%s\n", os.date()))
table.insert(tcontent, load_file('files.txt'))
table.insert(tcontent, load_file('multi_host_downloader/multi_host_downloader.log'))
table.insert(tcontent, load_file('multi_host_downloader/lua_error.log'))
table.insert(tcontent, load_file('multi_host_downloader/bash_error.log'))
table.insert(tcontent, load_file('multi_host_downloader/youtube-dl.log'))
table.insert(tcontent, strip_html('multi_host_downloader/gdrive_invalid_content.htm'))
table.insert(tcontent, strip_html('multi_host_downloader/videobin_invalid_content.htm'))
table.insert(tcontent, strip_html('multi_host_downloader/filedot_invalid_content.htm'))
table.insert(tcontent, strip_html('multi_host_downloader/letsupload_invalid_content.htm'))
table.insert(tcontent, strip_html('multi_host_downloader/pixeldrain_invalid_content.htm'))
table.insert(tcontent, strip_html('multi_host_downloader/mediafire_invalid_content.htm'))
res = gist.update('e1ea2560db98933916e42a1c47bdeec2', 'multi_host_downloader.log', table.concat(tcontent))

if os.date("%d")%7 == 0 then
	if os.date("%H") == "23" then
		if os.info() == "Windows" then 
			os.execute('type multi_host_downloader\\multi_host_downloader.log >> multi_host_downloader\\multi_host_downloader_history.log')
			os.remove('multi_host_downloader\\multi_host_downloader.log') 
		else
			os.execute('cat multi_host_downloader/multi_host_downloader.log >> multi_host_downloader/multi_host_downloader_history.log')
			os.remove('multi_host_downloader/multi_host_downloader.log') 
		end
		print('Archiving log at '..os.date())
	end
end
--print(res)
