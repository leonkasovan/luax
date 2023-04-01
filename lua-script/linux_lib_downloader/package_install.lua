#!/storage/bin/luax
-- Lua Script for searching and downloading linux(debian bullseye) package in https://packages.debian.org/
-- Jakarta, Cempaka Putih, 5:18 16 October 2022 dhani.novan@gmail.com
local pkg = require "package"
local n_downloaded_file = 0
local total_downloaded_filesize = 0

function all_depends(package_name, level)
	if level == nil then
		local fo
		root_package_name = package_name
		level = 0
		fo = io.open(root_package_name..'.txt', "w")
		fo:close()
	end
	packages = depends(package_name)
	for i,v in pairs(packages) do
		if v ~= "libc6" and v ~= "libgcc-s1" and v ~= "gcc-10-base" and v ~= "zlib1g" then
			print(string.rep('   ', level)..i..'. '..v)
			all_depends(v, level + 1)
		else
			print(string.rep('   ', level)..i..'. '..v)
		end
		
		if not file_search_value(root_package_name..'.txt', v) then
			local res, url, size = download(package_name, true)	-- get info from website: url and size
			if list_deb_files:find(http.resource_name(url),1,true) == nil then	-- file xxx.deb in /storage/deb haven't downloaded yet
				print('Downloading package '..package_name..' from '..url)
				local res = download(package_name)	-- real download the url
				n_downloaded_file = n_downloaded_file + 1
				total_downloaded_filesize = total_downloaded_filesize + tonumber(size)
			end
			append_file(root_package_name..'.txt', v..'\n')
		end
	end
end

handle = io.popen("ls /storage/deb/*.deb")
list_deb_files = handle:read("*all")
handle:close()

all_depends(arg[1])
print(string.format('\nTotal %d files deb downloaded\nTotal %d bytes', n_downloaded_file, total_downloaded_filesize))
