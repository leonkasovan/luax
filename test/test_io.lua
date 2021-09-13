-- Lua 5.1.5.XL Test Script for io Library

local fo
	
fo = io.open("test.htm","a+")
if fo ~= nil then
	print(fo:seek('set'))
	print(fo:write('\nfooter\n'))
	print(fo:seek('set', 1))
	print(fo:write('\nheader\n'))
	fo:close()
end