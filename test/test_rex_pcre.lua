-- Lua script for testing rex_pcre library
-- dhani_novan@gmail.com, Jakarta, 08/12/2020

print(pcre.version())
print(pcre._VERSION)

-- subject = "hello:world:lua:hello2:world2:lua2"
-- print(pcre.match(subject,'[a-z]+'))
-- print(pcre.find(subject,'[a-z]+'))

-- for v in pcre.gmatch(subject,'[a-z]+') do 
	-- print(v)
-- end

-- print(pcre.gsub(subject,'world', 'dunia'))

-- for v in pcre.split(subject,':') do 
	-- print(v)
-- end

url = 'https://imgtaxi.com/img-5f6ed35a87c6e.html'
url = 'http://imgdrive.net/img-5f6ed447549f2.html'
print(pcre.match(url, '^https://img(?:adult|taxi|drive)\\.(?:com|net)/img\\-\\w+\\.html'))

print(url:find('^http.?://'))

-- os.execute('pause')