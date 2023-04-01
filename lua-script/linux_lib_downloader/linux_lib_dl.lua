-- Lua Script for downloading needed shared/dynamic library in linux apps
-- Jakarta, Cempaka Putih, 5:18 16 October 2022 dhani.novan@gmail.com

local libs_needed = {}
local libs_provided = {}
local libs_not_provided = {}
local arch = 'arm64'	--armhf,amd64,i386
local dl_server = 'http://kartolo.sby.datautama.net.id/debian/'
-- alternate dl_server:
-- http://kebo.pens.ac.id/debian/
-- http://mirror.poliwangi.ac.id/debian/
-- http://mr.heru.id/debian/

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

-- return :
--	1. direct_url to download
--	2. package_size in byte
function search_lib(keyword)
	local result, package_name, package_size, subdirectory
	local rc, headers, content = http.request('https://packages.debian.org/search?searchon=contents&mode=path&suite=stable&arch=arm64&keywords='..keyword)
	if rc ~= 0 then
		print("Error: "..http.error(rc))
		return "",0
	end
	
	result = content:match('Found <strong>(%d-) results</strong>')
	if result == nil then
		print('Error: lib '..keyword..'not found')
		return "",0
	end
	
	package_name = content:match('<td>.-<a href=".-">(.-)</a>.-</td>')
	if package_name == nil then		
		print("Error: package_name can't be extracted")
		return "",0
	end
	-- print('Found at '..package_name..' package')
	
	rc, headers, content = http.request('https://packages.debian.org/bullseye/'..arch..'/'..package_name..'/download')
	if rc == nil then
		print("Error: "..http.error(rc))
		return "",0
	end
	
	package_name, subdirectory = content:match('for <kbd>(.-)</kbd>.-the <tt>(.-)</tt>')
	if result == nil then
		print("Error: package_name and subdirectory can't be extracted")
		return "",0
	end
	
	package_size = content:match('<th>Exact Size</th>	<td class="size">(%d-) Byte')
	if package_size == nil then
		print("Error: package_size and subdirectory can't be extracted")
		return "",0
	end
	
	print(dl_server..subdirectory..package_name, package_size)
	return dl_server..subdirectory..package_name, package_size
end

function load_libs_needed(elf_file)
	local handle, result, content

	handle = io.popen("readelf -d "..elf_file)
	content = handle:read("*all")
	handle:close()

	-- for line in io.lines("input_libs_needed.txt") do
	for line in content:gmatch("[^\r\n]+") do
		result = line:match('library%: %[(.-)%]')
		if result ~= nil then
			libs_needed[#libs_needed + 1] = result
		end
	end
	return #libs_needed
end

function load_libs_provided(t)
	local handle, result, content, path, filename
	
	for i,v in pairs(t) do
		handle = io.popen("ls "..v.."/*.so.*")
		content = handle:read("*all")
		handle:close()
		
		for line in content:gmatch("[^\r\n]+") do
			path, filename = line:match('^(/.+/)(%S+)$')
			if filename ~= nil then
				libs_provided[#libs_provided + 1] = filename
			end
		end
	end
	
	return #libs_provided
end

function load_libs_not_provided(elf_file)
	print(load_libs_needed(elf_file), "libs needed")
	load_libs_provided()
	
	for i,v in pairs(libs_needed) do
		if table_search_value(libs_provided, v) then
			print("provided", v)
		else
			print("  needed", v)
			libs_not_provided[#libs_not_provided + 1] = v
		end
	end
	
	print(#libs_not_provided, "libs not provided")
	print(#libs_needed-#libs_not_provided, "libs provided")
end

-- load_libs_needed('yad')
-- load_libs_provided({'/usr/lib', '/storage/roms/lib'})
-- load_libs_not_provided('yad')

print(load_libs_needed('yad'))
for i,v in pairs(libs_needed) do
	print(i,v)
end

-- print(load_libs_provided({'/usr/lib', '/storage/roms/lib'}))
-- for i,v in pairs(libs_provided) do
	-- print(i,v)
-- end

