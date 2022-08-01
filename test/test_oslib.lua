-- Lua 5.1 Tes Script for OS Library addons

os.execute("dir")

print("Current Working Directory: "..os.getcwd())
filename = 'readme.txt'
print(filename.." size : "..os.getfilesize(filename))
print("MD5 Checksum: "..os.checksum(filename))
-- os.execute("pause")