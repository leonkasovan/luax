-- Lua 5.1.5.XL Test Script for cjson Library
-- Additional path that may be required

json_text = '[ true, { "foo": "bar" } ]'
value= json.decode(json_text)

for i,v in pairs(value) do
	print(i,v)
end

value = { true, { foo = "bar" } }
json_text = json.encode(value)

print(json_text)