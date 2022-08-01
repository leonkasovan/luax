-- Lua 5.1.5.XL Script for collecting real google drive links in https://terbit21.blog/
-- 13/12/2020 Jakarta Rawamangun, dhani.novan@gmail.com

-- url = 'https://terbit21.blog/'
-- rc, headers, content = http.request(url)
-- if rc ~= 0 then
	-- print("Error: "..http.error(rc))
	-- return false
-- end
-- links = http.collect_link(content, url)
-- for i,v in pairs(links) do
	-- if v:match('%-%d%d%d%d') ~= nil then
		-- print(i,v)
	-- end
-- end

url = 'https://terbit21.blog/clowntergeist-2017/'
movie_id = url:match('%.%S+%/(%S+%-%d%d%d%d)/')
print(movie_id)
if movie_id == nil then
	print('Error: invalid input url. Can not find movie_id')
	return false
end

url2 = 'https://terbit21.blog/get/?movie='..movie_id
rc, headers, content = http.request(url2)
if rc ~= 0 then
	print("Error: "..http.error(rc))
	return false
end
url3 = content:match('<a id="downloadbutton" href="(.-)"')
print(url3)
if url3 == nil then
	print('Error: invalid response. Can not find movie_id')
	return false
end

rc, headers = http.request{url = url3, output_filename = 'content.htm'}
if rc ~= 0 then
	print("Error: "..http.error(rc))
	return false
end
print(headers)