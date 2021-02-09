-- Lua 5.1.5.XL Test Script for IUP Library

btn1 = iup.button{title = "Click me!"}
btn2 = iup.button{title = "and me!"}

function btn1:action ()
    iup.Message("Note","I have been clicked!")
end

function btn2:action ()
    iup.Message("Note","Me too!")
end


-- box1 = iup.vbox {btn1,btn2}
box1 = iup.hbox {btn1,btn2; gap=4}
dlg1 = iup.dialog{box1; title="Simple Dialog",size="QUARTERxQUARTER"}

edit1 = iup.multiline{expand="YES",value="Number 1"}
edit2 = iup.multiline{expand="YES",value="Number 2?"}
box2 = iup.hbox {iup.frame{edit1;Title="First"},iup.frame{edit2;Title="Second"}}
dlg2 = iup.dialog{box2; title="Simple Dialog",size="QUARTERxQUARTER"}

timer = iup.timer{time=500}
btn3 = iup.button {title = "Stop",expand="YES"}
function btn3:action ()
    if btn3.title == "Stop" then
        timer.run = "NO"
        btn3.title = "Start"
    else
        timer.run = "YES"
        btn3.title = "Stop"
    end
end
function timer:action_cb()
    print 'timer!'
end
timer.run = "YES"
dlg3 = iup.dialog{btn3; title="Timer!"}

dlg1:show()
dlg2:show()
dlg3:show()
iup.MainLoop()