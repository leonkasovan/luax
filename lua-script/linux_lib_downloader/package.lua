-- Lua Script for searching and downloading linux(debian bullseye) package in https://packages.debian.org/
-- Jakarta, Cempaka Putih, 5:18 16 October 2022 dhani.novan@gmail.com

-- libname: package
-- function download(package_name) package_name: libogg0  make gcc libnsl-dev
-- function depends(package_name) package_name: libogg0 make gcc libnsl-dev
-- function search(exact_filename_in_package) filename: libogg.so.0

local arch = 'arm64'	--armhf,amd64,i386
local dl_server = 'http://kartolo.sby.datautama.net.id/debian/'
-- alternate dl_server:
-- http://kebo.pens.ac.id/debian/
-- http://mirror.poliwangi.ac.id/debian/
-- http://mr.heru.id/debian/
local root_package_name = ''

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

function append_file(filename, content)
	local fo
	
	fo = io.open(filename, "a")
	if fo == nil then
		print('Error open a file '..filename)
		return false
	end
	fo:write(content)
	fo:close()
	return true
end

-- return : 
--	1. true if val is found in the table
--	2. false if val is not found in the table
function file_search_value(filename, val)
	local content = load_file(filename)

	-- print('content\n'..content)
	if string.find(content, val, 1, true) ~= nil then
		-- print('file_search_value', filename, val, 'found/true')
		return true
	end
	-- print('file_search_value', filename, val, 'not found/false')
	return false
end

-- return : 
--	1. true if val is found in the table
--	2. false if val is not found in the table
function table_search_value(t, val)
	for i,v in pairs(t) do
		if v == val then
			return true
		end
	end
	return false
end

-- return true(, package_url, package_size): success
-- return false: fail
function download(package_name, justinfo)
	local rc, headers, content
	local package_filename, package_size, subdirectory
	
	rc, headers, content = http.request('https://packages.debian.org/bullseye/'..arch..'/'..package_name..'/download')
	if rc == nil then
		print("Error: "..http.error(rc))
		return false
	end
	
	package_filename, subdirectory = content:match('for <kbd>(.-)</kbd>.-the <tt>(.-)</tt>')
	if package_name == nil then
		print("Error: package_name can't be extracted")
		return false
	end
	
	if subdirectory == nil then
		print("Error: subdirectory can't be extracted")
		return false
	end
	
	package_size = content:match('<th>Exact Size</th>	<td class="size">(%d-) Byte')
	if package_size == nil then
		print("Error: package_size can't be extracted")
		return false
	end
	
	if justinfo == true then
		print(package_name, dl_server..subdirectory..package_filename, package_size)
		return true, dl_server..subdirectory..package_filename, package_size
	end
	
	http.set_conf(http.OPT_TIMEOUT, 600)
	rc, headers = http.request{url = dl_server..subdirectory..package_filename, output_filename = package_filename}
	if rc ~= 0 and rc ~=33 then
		print("Error: "..http.error(rc), rc)
		return false
	end
	return true
end

-- return package_name
-- return false if any error
function search(exact_filename)
	local result, package_name, package_size, subdirectory
	local rc, headers, content = http.request('https://packages.debian.org/search?searchon=contents&mode=path&suite=stable&arch=arm64&keywords='..exact_filename)
	if rc ~= 0 then
		print("Error: "..http.error(rc))
		return false
	end
	
	result = content:match('Found <strong>(%d-) results</strong>')
	if result == nil then
		print('Error: filename '..exact_filename..' not found')
		return false
	end
	
	package_name = content:match('<td>.-<a href=".-">(.-)</a>.-</td>')
	if package_name == nil then		
		print("Error: package_name can't be extracted")
		return false
	end
	
	return package_name
end

function depends(package_name)
	local t
	local rc, headers, content = http.request('https://packages.debian.org/bullseye/'..package_name)
	if rc ~= 0 then
		print("Error: "..http.error(rc))
		return false
	end
	
	t = {}
	for w in content:gmatch('dep%:</span>.-<a href="/bullseye/(.-)">') do
		if not table_search_value(t, w) then
			t[#t + 1] = w
		end
	end
	
	return t
end

return {
	download = download,
	search = search,
	depends = depends
}

--download('cpp', true)
--download('gcc')
-- package_name = search('libogg.so.0')
-- if package_name then
	-- print(package_name)
-- end

-- all_depends(arg[1])
-- all_depends('yad')

-- content = [[
-- libc6
-- libgcc-s1
-- libluajit-5.1-2
-- libluajit-5.1-common
-- ]]

-- if string.match(content, arg[1]) ~= nil then
	-- print('found', arg[1])
-- else
	-- print('not found', arg[1])
-- end
