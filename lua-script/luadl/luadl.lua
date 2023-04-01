-- if #arg < 1 then
	-- print("Lua downloader: [url]")
	-- return 0
-- end
http.set_conf(http.OPT_TIMEOUT, 1800)

content = [[
https://github.com/JustEnoughLinuxOS/distribution/releases/download/20221114/JELOS-RG353P.aarch64-20221114.img.gz
]]

for line in content:gmatch("[^\r\n]+") do
	n = 1
	repeat
		print(n, "Downloading ", line)
		rc, headers = http.request{url = line, output_filename = http.resource_name(line)}
		if rc ~= 0 then
			print("Error: "..http.error(rc), rc)
			n = n + 1
		end
	until (n > 10) or (rc == 0)
end
