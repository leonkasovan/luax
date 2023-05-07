-- Common used lua library
-- Dhani Novan, 27/02/2021, Rawamangun

function path_sep()
	if os.info() == "Windows" then
		return '\\'
	else
		return '/'
	end
end

function printf(...)
	return print(string.format(...))
end

-- str1 = "12345" return true
-- str2 = "abc123" return false
function is_string_all_digit(str)
    return string.match(str, "%D") == nil and string.len(str) > 0
end

function format_number(s)
    local pos = string.len(s) % 3

    if pos == 0 then pos = 3 end
    return string.sub(s, 1, pos).. string.gsub(string.sub(s, pos+1), "(...)", ".%1")
end

function format_bytes(s)
    local units = {"B", "KB", "MB", "GB", "TB", "PB", "EB"}
    local unitIndex = 1
    local size
	
	if type(s) == "string" then
		size = tonumber(s)
	elseif type(s) == "number" then
		size = s
	else
		return false
	end
    while size >= 1024 and unitIndex < #units do
        size = size / 1024
        unitIndex = unitIndex + 1
    end

    return string.format("%.2f %s", size, units[unitIndex])
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

