-- Test populate table with string to concat them

local mytable = {};
for i=1, 10 do
	mytable[#mytable+1] = 'data ke '..tostring(i);
end

print(table.concat(mytable))
print(table.concat(mytable, ';'))

for i,v in pairs(_G) do
	print(i,v)
end