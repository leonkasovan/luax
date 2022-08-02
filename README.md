# Welcome to LuaX

LuaX is lua (v5.1.5) scripting language with eXtra (built-in) Library : <b>http iup json pcre csv gzio lfs</b>
for both Linux and Windows (Visual Studio 2012).

Contact:
e-mail: dhani.novan@gmail.com
instagram: https://www.instagram.com/dhaninovan/

Simple sample to use <b>http</b> Library:
```lua
rc, http_headers, http_content = http.request('https://pixeldrain.com/u/5wMxR7BV')
if rc ~= 0 then
	print("Error: "..http.error(rc))
	return nil
end
print(http_headers)
print(http_content)
filename = string.match(content, 'og%:title" content="(.-)"')
print(filename)
```

Simple sample to use <b>json</b> Library:
```lua
json_text = '[ true, { "foo": "bar" } ]'
value= json.decode(json_text)

for i,v in pairs(value) do
	print(i,v)
end

value = { true, { foo = "bar" } }
json_text = json.encode(value)
```

Simple sample to use <b>pcre</b> Library:
```lua
print(pcre.version())
subject = "hello:world:lua:hello2:world2:lua2"
print(pcre.match(subject,'[a-z]+'))
print(pcre.find(subject,'[a-z]+'))

for v in pcre.gmatch(subject,'[a-z]+') do 
	print(v)
end

print(pcre.gsub(subject,'world', 'dunia'))

for v in pcre.split(subject,':') do 
	print(v)
end
```

Simple sample to use <b>csv</b> Library:
```lua
data,header = csv.reader('test1.csv', ',')
if header then print('header', header[1], header[2], header[3], header[4]) end
for row in data:rows() do
    print('data', row[1], row[2], row[3], row[4])
end
```

Prerequisite (Linux):
```
sudo apt install libreadline-dev libcurl4-openssl-dev libpcre3-dev libz-dev
```

How to build (Linux):
```
git clone https://github.com/leonkasovan/luax.git
make
bin/lua
```

How to build (Windows):
```
1. Open file luax.sln
2. Select lua project
3. Press build (F7)
4. Run binary output in bin folder
```


Git commands update and merge from repository:
```
git pull
```

Git commands after edit some files:
```
git config credential.helper store
git commit -a
git push
```

Git commands cancel edit some files (before git add):
```
git checkout .
```

