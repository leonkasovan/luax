-- Common used lua library
-- Dhani Novan, 27/02/2021, Rawamangun

function path_sep()
	if os.info() == "Windows" then
		return '\\'
	else
		return '/'
	end
end

function format_number(s)
    local pos = string.len(s) % 3

    if pos == 0 then pos = 3 end
    return string.sub(s, 1, pos).. string.gsub(string.sub(s, pos+1), "(...)", ".%1")
end

function save_file(content, filename)
	local fo
	
	fo = io.open(filename, "w")
	fo:write(content)
	fo:close()
end

function load_file(filename)
	local fi, content

	fi = io.open(filename, "r")
	if fi == nil then
		print("[error][common.load_file] Can't open "..filename)
		return nil
	end
	content = fi:read("*a")
	fi:close()
	return content
end

function import_library(url)
	local rc, code, headers

	rc, headers, code = http.request(url)
	if rc ~= 0 then
		print("[error][common.import_library] "..http.error(rc))
		return nil
	end
	return loadstring(code)()
end

