-- Download file from solidfiles.com
-- Format Input URL = 
--          http://www.solidfiles.com/%w/%w+
--			http://www.solidfiles.com/v/nDNxPz27RwYvM
--			http://www.solidfiles.com/d/b007fccb0d/
-- Interpreter : modified lua https://drive.google.com/file/d/1imqMbflxEEc8OsTCJoHiuMufdAfJTNSg/view?usp=drivesdk
-- 4:36 19 July 2020, Rawamangun

-- GLOBAL SETTING
local MAXTIMEOUT = 900	-- set max timeout 15 minutes
local LOG_FILE = "solidfiles.log"
local DEBUG = true	-- write all log to a file (LOG_FILE)
--local DEBUG = false	-- write all log to console output

function my_write_log(data)
	local fo
	if DEBUG then 
		fo = io.open(LOG_FILE, "a")
		if fo == nil then
			print("Can not open "..LOG_FILE)
			return nil
		end
		fo:write(table.concat{os.date(), " ", data, "\n"})
		fo:close()
		return true
	else
		print(data)
		return true
	end
end

function save_file(content, filename)
	local fo
	
	fo = io.open(filename, "w")
	fo:write(content)
	fo:close()
end

-- Output :
--	true : on success
--	false : fail, timeout or network problem (can be retried)
--	nil : fail, invalid response
function download_solidfiles(url, callback_function_write_log, callback_function_on_success)
    local rc, content, filename, filesize, form_url, token, action_url, action_form
    local write_log
 
	if callback_function_write_log ~= nil then
		write_log = callback_function_write_log
	else
		write_log = my_write_log
	end
	
    rc, content = http.get_url(url)
    if rc ~= 0 then
        write_log("[error][solidfiles.download] "..http.error(rc))
        return false
    end
    filename = string.match(content, '<h1 class="node%-name">(.-)</h1>')
    if filename == nil then
        write_log("[error][solidfiles.download] Can't find it's filename. Invalid response from SolidFiles.com")
        save_file(content,"solidfiles_invalid_content.htm")
        return nil
    end
    filename = filename:gsub('[%/%\%:%?%*%"%<%>%|]', "")
    
    filesize = string.match(content, '</copy%-button>%s+(.-)%-')
    if filesize == nil then
        filesize = ""
    end
    filesize = filesize:gsub('[^%w%.]','')
    
    form_url, token = string.match(content, "<form action=\"(.-)\" method=\"post\">\n                                                <input type='hidden' name='csrfmiddlewaretoken' value='(.-)' />")
    if form_url == nil or token == nil  then
        write_log("[error][solidfiles.download] Can't find it's form action and token. Invalid response from SolidFiles.com")
        save_file(content,"solidfiles_invalid_content.htm")
        return nil
    end
    
    http.set_conf(http.OPT_TIMEOUT, MAXTIMEOUT)
    action_url = 'http://www.solidfiles.com'..form_url
    action_form = 'referrer=www.google.com&csrfmiddlewaretoken='..token
    rc, content = http.post_form(action_url, action_form)
    if rc ~= 0 then
        write_log("[error][solidfiles.download] "..http.error(rc))
        return false
    end
    
    action_url = string.match(content, 'seconds, <a href="(.-)">click here</a>')
    if action_url == nil then
        write_log("[error][solidfiles.download] Can't find direct link. Invalid response from SolidFiles.com")
        save_file(content,"solidfiles_invalid_content.htm")
        return nil
    end
    http.set_conf(http.OPT_TIMEOUT, MAXTIMEOUT)
    rc = http.get_url(action_url, filename)
    if rc ~= 0 then
        write_log("[error][solidfiles.download] "..http.error(rc))
        return false
    end
    
    -- Update success list of URL
    os.remove('http_header.txt')
    if callback_function_on_success ~= nil then callback_function_on_success(string.format("%s %s; %s (%s)", os.date(), url, filename, filesize)) end
    write_log(string.format("[info][solidfiles.download] Success saving file %s (%s)", filename, filesize))
    return true
end

function verify_solidfiles(url)
	return url:match('^http://www.solidfiles.com/%w/%w+')
end

return {
	download = download_solidfiles,
	verify = verify_solidfiles
}
