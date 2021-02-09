-- Lua 5.1.5.XL Test Script for gzio Library

-----------------------------------------------------------------------------
-- gzip file I/O library test script
--
-- This file was created by Judge Maygarden (jmaygarden at computer dot org)
-- and is hereby place in the public domain
-----------------------------------------------------------------------------

local filename = "E:\\Projects\\LUA Script\\BRI Report\\Otista\\DI319 PN PENGELOLAH V2 31 DESEMBER 2020.csv"
local gzFile

-- stream the text file into a gzip file
gzFile = assert(gzio.open(filename..".gz", "w"))
for line in io.lines(filename) do
	gzFile:write(line..'\n')
end
gzFile:close()


-- echo the gzip file to stdout
-- gzFile = assert(gzio.open(filename..".gz", "r"), "gzio.open failed!")
-- for line in gzFile:lines() do
	-- print(line)
-- end

-- rewind and do it again with gzFile:read
-- gzFile:seek("set")
-- print(gzFile:read("*a"))

-- gzFile:close()

-- Case 1: simple read from gz file by line 
-- for line in gzio.lines("test.csx.gz") do
	-- print(line)
-- end

