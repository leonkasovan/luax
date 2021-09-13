local pre = collectgarbage("count")
local table = {1, 2, 3, 4, 5}
local aft = collectgarbage("count")

local probablyTableSize = aft - pre
print(pre, aft, probablyTableSize)

print(gcinfo())
