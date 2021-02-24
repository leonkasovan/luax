-- Lua Script : Update log in gist.github.com
-- Using modified Lua 5.1 https://drive.google.com/file/d/1imqMbflxEEc8OsTCJoHiuMufdAfJTNSg/view?usp=sharing
local LOG_FILE = "multi_host_downloader/multi_host_downloader.log"
local LOG_FILE2 = "youtube-dl.log"

function myload_file(filename)
    local fi, content
 
    fi = io.open(filename, "r")
    if fi == nil then
        return ""
    end
    content = fi:read("*a")
    fi:close()
    return content
end

if os.date("%H") == "05" or os.date("%H") == "22" or os.date("%H") == "17" then
	os.remove('file.tmp')
	os.remove(LOG_FILE2)
end
if os.date("%d")%2 == 0 then
	if os.date("%H") == "22" then os.remove('multi_host_downloader.log') end
end

if os.info() == "Windows" then
	gist = require('github/gist')
	os.execute('dir /A:-D /O:D > files.txt')	
else
	gist = require('github\gist')
	os.execute("ls -lt multi_host_downloader > files.txt")
end

res = gist.update('e1ea2560db98933916e42a1c47bdeec2', 'multi_host_downloader.log', string.format("Time:%s\n %s\n\nLOG LUA Downloader:\n%s\n\nLOG Youtube-DL:\n%s", os.date(), myload_file('files.txt'), myload_file(LOG_FILE), myload_file(LOG_FILE2)))

