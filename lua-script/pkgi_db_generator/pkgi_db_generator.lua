-- Lua Script : Generate db(in txt) for application "pkgi" from data source in https://nopaystation.com
-- Using modified Lua 5.1
-- 8:48 16 April 2023, Dhani Novan, Jakarta Cempaka Putih

dofile('../strict.lua')

local OUTPUT_SEPARATOR = '|'

function generate_dbformat()
	local fo
	
	fo = io.open("dbformat.txt", "w")
	if fo == nil then
		print('Error create file dbformat.txt')
		return false
	end
	fo:write(OUTPUT_SEPARATOR.."\ncontentid"..OUTPUT_SEPARATOR.."name"..OUTPUT_SEPARATOR.."url"..OUTPUT_SEPARATOR.."rap"..OUTPUT_SEPARATOR.."size\n")
	fo:close()
	return true
end

function convert_db(finput,foutput)
	local fo, line
	
	fo = io.open(foutput, "w")
	if fo == nil then
		print('Error create file '..foutput)
		return false
	end
	for line in io.lines(finput) do
		local f
		if line ~= nil and line ~= "" then
			f = csv.parse(line, '\t')
			if f ~= nil then
				fo:write(f[6]..OUTPUT_SEPARATOR..f[3]..OUTPUT_SEPARATOR..f[4]..OUTPUT_SEPARATOR..f[5]..OUTPUT_SEPARATOR..f[9].."\n")
			end
		end
	end
	fo:close()
	return true
end

generate_dbformat()
print("Downloading PS3 GAMEs")
rc, headers = http.request{url = 'https://nopaystation.com/tsv/PS3_GAMES.tsv', output_filename = 'PS3_GAMES.tsv'}
if rc ~= 0 then
	print("Error: "..http.error(rc), rc)
	return false
end
print("Converting PS3 GAMEs")
if convert_db("PS3_GAMES.tsv", "pkgi_games.txt") then
	print("Process PS3_GAMES success.")
else
	print("Process PS3_GAMES fail.")
end

print("Downloading PS3 DLCs")
rc, headers = http.request{url = 'https://nopaystation.com/tsv/PS3_DLCS.tsv', output_filename = 'PS3_DLCS.tsv'}
if rc ~= 0 then
	print("Error: "..http.error(rc), rc)
	return false
end
print("Converting PS3 DLCs")
if convert_db("PS3_DLCS.tsv", "pkgi_dlcs.txt") then
	print("Process PS3_DLCS success.")
else
	print("Process PS3_DLCS fail.")
end

print("If all success, copy *.txt to PS3 /dev_hdd0/game/NP00PKGI3/USRDIR")