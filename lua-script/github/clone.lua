-- Clone specific directory from github.com
-- 11:22 19 August 2023, Dhani Novan, Jakarta, Cempaka Putih

dofile('../strict.lua')
dofile('../common.lua')

function download_directory(path)
	local value
	local rc, headers, content = http.request(path)
	if rc ~= 0 then
		print("Error: "..http.error(rc), rc)
		return false
	end
	value = json.decode(content)
	for i,v in pairs(value.payload.tree.items) do
		if v.contentType == "directory" then
			print("\nNew directory "..v.name)
			lfs.mkdir(v.name)
			lfs.chdir(v.name)
			download_directory(path..'/'..v.name)
			lfs.chdir("..")
		else --v.contentType == "file"
			print("Download file "..v.name)
			rc, headers = http.request{url = path..'/'..v.name, output_filename = v.name}
			if rc ~= 0 then
				print("Error: "..http.error(rc), rc)
			end
		end
	end
	return true
end

download_directory('https://github.com/batocera-linux/batocera.linux/tree/master/board/batocera/rockchip/rk3399')
