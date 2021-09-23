local pre = collectgarbage("count")
local table = {1, 2, 3, 4, 5}
local aft = collectgarbage("count")

local probablyTableSize = aft - pre
print(pre, aft, probablyTableSize)

print(gcinfo())

-- step 2
print("Test GC - Step 2")
mytable = {"apple", "orange", "banana"}
print(collectgarbage("count"))
mytable = nil
print(collectgarbage("count"))
print(collectgarbage("collect"))
print(collectgarbage("count"))