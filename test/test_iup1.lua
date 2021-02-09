-- Lua 5.1.5.XL Test Script for IUP Library

b = iup.Alarm("IupAlarm Example", "File not saved! Save it now?" ,"Yes" ,"No" ,"Cancel")

-- Shows a message for each selected button
if b == 1 then
  iup.Message("Save file", "File saved sucessfully - leaving program")
elseif b == 2 then
  iup.Message("Save file", "File not saved - leaving program anyway")
elseif b == 3 then
  iup.Message("Save file", "Operation canceled")
end

f, err = iup.GetFile("*.lua")
if err == 1 then
  iup.Message("New file", f)
elseif err == 0 then
  iup.Message("File already exists", f)
elseif err == -1 then
  iup.Message("IupFileDlg", "Operation canceled")
end

res = iup.GetText("Give me your name","")
if res ~= "" then
    iup.Message("Thanks!",res)
end

res, name = iup.GetParam("Title", nil,
    "Give your name: %s\n","")
iup.Message("Hello!",name)

res, prof = iup.GetParam("Title", nil,
    "Give your profession: %l|Teacher|Explorer|Engineer|\n",0)
iup.Message("Your profession!",prof)

res, age = iup.GetParam("Title", nil,
    "Give your age: %i\n",0)
if res ~= 0 then    -- the user cooperated!
    iup.Message("Really?",age)
end
