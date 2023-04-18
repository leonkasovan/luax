-- Lua 5.1 Script
print(http.version())

-- simple http request
-- rc, headers, content = http.request('http://www.google.com')

-- simple http request
-- rc, headers, content = http.request('https://qwerty.com')
-- if rc ~= 0 then
	-- print("Error: "..http.error(rc))
-- else
	-- print("Success")
-- end

-- simple http request
-- print(http.request('https://pastebin.com/raw/duJXq19G'))
-- print(http.request('https://notepad-plus-plus.org/update/getDownloadUrl.php?version=7.91&param=x64'))

-- simple http post request
-- print(http.request('https://httpreq.com/square-snowflake-ev568uhe/record','foo=bar'))
-- simple http get request
-- print(http.request('https://httpreq.com/square-snowflake-ev568uhe/record?hello=world'))


-- simple generic request
-- print(http.request{url = 'https://www.google.com'})
-- download and save into file
-- print(http.request{url = 'https://www.google.com', output_filename = 'google.htm'})

-- download and save into file
-- target_url = 'https://github.com/downloads/rrthomas/lrexlib/lrexlib-2.7.1.zip'
-- target_filename = http.resource_name(target_url)
-- print(http.request{url = target_url, output_filename = target_filename})
http.set_conf(http.OPT_REFERER, 'https://www.google.com')
http.set_conf(http.OPT_TIMEOUT, 60)
http.set_conf(http.OPT_USERAGENT, 'Opera/9.80 (J2ME/MIDP; Opera Mini/7.1.32052/29.3417; U; en) Presto/2.8.119 Version/11.10')
http.set_conf(http.OPT_VERBOSE, true)
http.set_conf(http.OPT_COOKIEFILE, 'cookies.txt')
http.set_conf(http.OPT_NOPROGRESS, false)
-- add custom header
print(http.request{
	url = 'https://notepad-plus-plus.org/update/getDownloadUrl.php?version=7.91&param=x64', 
	method = 'GET',
	headers = { 'X-Accept: text/lua', 'X-Custom: halo-there'}})

-- download and save into file
-- print(http.request{url = 'https://www.google.com', output_filename = 'google.htm'})

os.execute("pause")
