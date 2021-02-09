-- Lua 5.1.5.XL Test Script for CSV Library

content = "John,Bobby,Agus,Budi"
col = csv.parse(content, ',')
print(col[1], col[2], col[3], col[4])


for i,v in pairs(col) do
	print(i,v)
end

for i,v in pairs(csv.parse(content, ',')) do
	print(i,v)
end

--table into string csv
print(csv.convert{'one','two','three',12,34,56,99})

-- read csv data from file : method 1 preferred
-- data,header = csv.reader(filename: string, delimiter:string(,), has_header: bool(true), convert_number: bool(true))
data,header = csv.reader('test1.csv')
if header then print('header', header[1], header[2], header[3], header[4]) end
for row in data:rows() do
    print('data', row[1], row[2], row[3], row[4])
end
-- auto close file handle

-- read csv data from file : method 2
-- data,header = csv.reader(filename: string, delimiter:string(,), has_header: bool(true), convert_number: bool(true))
data,header = csv.reader('test1.csv')
if header then print(header[1], header[2], header[3], header[4]) end
row = data:read()
while row do
    print(row[1], row[2], row[3], row[4])
    row = data:read()
end
data:close()

-- read csv data from file : method 1 
-- data,header = csv.reader(filename: string, delimiter:string(,), has_header: bool(true), convert_number: bool(true))
data,header = csv.reader('test1.csv', ',')
if header then print('header', header[1], header[2], header[3], header[4]) end
for row in data:rows() do
    print('data', row[1], row[2], row[3], row[4])
end

-- write csv data into file
-- w = csv.writer(filename: string, delimiter:string(,))
w = csv.writer('output.csv')
w:write {10,20,30}
w:write {'satu','dua','tiga'}
w:close()

-- write csv data into stdout
-- w = csv.writer(filename: string, delimiter:string(,))
w = csv.writer('stdout')
w:write {10,20,30}
w:write {'satu','dua','tiga'}

os.execute("pause")

