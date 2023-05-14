-- http://mpeterv.github.io/luazip/manual.html#reference

local zfile, err = zip.open('luazip.zip')

-- print the filenames of the files inside the zip
for file in zfile:files() do
    print(file.filename)
end

-- open README and print it
local f1, err = zfile:open('README')
local s1 = f1:read("*a")
print(s1)

f1:close()
zfile:close()

-- open d.txt inside c.zip
local d, err = zip.openfile('a/b/c/d.txt')
assert(d, err)
d:close()

-- open d2.txt inside b2.ext2
local d2, err = zip.openfile('a2/b2/c2/d2.txt', "ext2")
assert(d2, err)
d2:close()

-- open d3.txt inside a3.ext3
local d3, err = zip.openfile('a3/b3/c3/d3.txt', {"ext2", "ext3"})
assert(d3, err)
d3:close()