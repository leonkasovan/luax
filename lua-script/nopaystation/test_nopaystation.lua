-------------------------------------------------------------------------------
--	Library Testing
-------------------------------------------------------------------------------

local nopaystation = dofile('nopaystation.lua')

content = [[
http://nopaystation.com/view/PS3/NPEB02246/TMNINJATU2015PS3/1?version=1.02
]]

local MAXTRY = 3
local done, try
for url in content:gmatch("[^\r\n]+") do
	if nopaystation.verify(url) then
		done = nopaystation.download(url)
		try = 1
		while ((try <= MAXTRY) and (done == false)) do
			print('Retry '..try)
			done = nopaystation.download(url)
			try = try + 1
		end
	else
		print('[error][nopaystation] invalid URL')
	end
end
