--Signal Server
--PeachMaster's MTC and Digital Interlocking System (TrainControl)

--Required APIs
local event = require("event")
local filesystem = require("filesystem")
local thread = require("thread")
local serialization = require("serialization")
local comp = require("component")
local term = require("term")
local sides = require("sides")
local minitel = require("minitel")
local computer = require("computer")
local theTimer

local function read_file(path)
    local file = io.open(path) -- r read mode and b binary mode
    if not file then return nil end
    local content = file:read("*a") -- *a or *all reads the whole file
    file:close()
    return content
end

local function write_file(path, what)
    local file = io.open(path, "w")
    if not file then return nil end
    file:write(serialization.serialize(what))
    file:close()
end

local function getSomethingFromTable(theTable, thingWanted) -- A workaround to crappy CC/Lua. >:( 
    for k, v in pairs(theTable) do
        if k == thingWanted then
            return v
        end
      end
end

local function decryptMessage(leMessage) --Not implimented, just return
    return leMessage
end

local function encryptMessage(leMessage) --Not implimented, just return
    return leMessage
end

local function sendModem(leMessage, theSignal, protocol)
    minitel.rsend(getSomethingFromTable(theSignal, "computerHostname"), 1337, false)
end

local function justSendSomething(leMessage, hostname)
    return  minitel.rsend(hostname, 1337, serialization.serialize(encryptMessage(leMessage)))
end

local function saveTableFile(path, watchuwant)
    write_file(path, watchuwant)
end

local function loadTableFile(path)
    return serialization.unserialize(read_file(path))
end


local signalBlocks = {}
local config = {}

--Required components
local modem = comp.modem
local gpu = comp.gpu

local function cWrite( text, fgc, pIndex )
	local old_fgc, isPalette = gpu.getForeground()
	pIndex = ( type( pIndex ) == 'boolean' ) and pIndex or false
	gpu.setForeground( fgc, pIndex )
	gpu.setForeground( old_fgc, isPalette )
end -- End of cWrite()

local function addProtocol(ttable, theProtocol)
return table.insert(ttable, {protocol = theProtocol})
end

local function updateDisplay()
    term.clear()
    local theSignalBlocks = table.sort(signalBlocks)
    
    for k, v in pairs(theSignalBlocks) do
        term.write(k..": ")
        if v["status"] == 0 then
          cWrite("Green", 0x339933)
        end
        if v["status"] == 1 then
            cWrite("Blinking Yellow", 0x339933)
        end
        if v["status"] == 2 then
            cWrite("Blinking Yellow", 0xFFFF00)
        end
        if v["status"] == 3 then
            cWrite("Red", 0xCC0000)
        end

    end

end


local function doControls()


    --Switch things up, no longer use event.pull cuz that can cause issues

    event.listen("net_msg", function(event, senderName, port, message)
        message = decryptMessage(message)
        print(event,senderName,port,message,protocol)
       
        if message ~= nil then
            message = serialization.unserialize(message)
            protocol = getSomethingFromTable(message, "protocol")
            if senderName == getSomethingFromTable(config, "serverID") then
                if protocol == "HelloPing" then
                    minitel.rsend(senderName, 1337, encryptMessage(serialization.serialize({protocol = "ConnectionOkay!"})))
                end

                if protocol == "UpdateSignalAll" then
                    for k, v in pairs(getSomethingFromTable(message, "theSignals")) do
                        if (v ~= "UpdateSignalAll" or v ~= "ASignal") then
                            signalBlocks[k].status = v["status"]
                            print("Status updated!")

                        if config["outputSignals"] == true then
                            local theController = comp.proxy(getSomethingFromTable(signalBlocks[k], "signalOutputColor"))
                            if signalBlocks[k].status == 0 then
                                theController.setAspect("green")
                            end
                            if signalBlocks[k].status == 1 then
                                theController.setAspect("blink_yellow")
                            end
                            if signalBlocks[k].status == 2 then
                                theController.setAspect("yellow")
                            end
                            if signalBlocks[k].status == 3 then
                                theController.setAspect("red")
                            end
                        end
                            print("aspects updated!")
                        end
                        
                        if config["doMTC"] then

                        end

                    end
                    updateDisplay()
                end

                if protocol == "UpdateSignal" then
                    if signalBlocks[message["signal"]] ~= nil then
                        signalBlocks[message["signal"]]["status"] = message["status"]
                        
                     if config["outputSignals"] == true then
                        local theController = comp.proxy(signalBlocks[message["signal"]]["signalOutputColor"] )
                        
                        if signalBlocks[message["signal"]]["status"]  == 0 then
                            theController.setAspect("green")
                        end
                        if signalBlocks[message["signal"]]["status"]  == 1 then
                            theController.setAspect("blink_yellow")
                        end
                        if signalBlocks[message["signal"]]["status"]  == 2 then
                            theController.setAspect("yellow")
                        end
                        if signalBlocks[message["signal"]]["status"]  == 3 then
                            theController.setAspect("red")
                        end
                     end

                     

                        print("Updated signal "..message["signal"].." to "..message["status"])

                    end
                end
                
            end

        end

    end)

    event.listen("redstone_changed", function()
        print("Redstone change!")
        for k, v in pairs(signalBlocks) do
            print(k)
            if comp.redstone.getInput(sides[getSomethingFromTable(signalBlocks[k], "signalInputColor")]) == 15 then
                signalBlocks[k].status = 3
                print(k.." is now active!")
            else
                signalBlocks[k].status = 0
                print(k.." is now inactive!")
            end

        end -- end of k, v in pairs(signalBlocks) do

        --Okay sure we know which one is on or off, but we have to check up with the server
        -- to make sure that we are right. Send the signals to the server.
        local toSend = {}
        toSend["theSignals"] = signalBlocks
        toSend["protocol"] = "SignalUpdate"
        print("we got here..")
        minitel.send(getSomethingFromTable(config, "serverID"), 1337, encryptMessage(serialization.serialize(toSend)))
        print("Sent signals to the server, hoping we get a response..")
    end)


end -- End of doControls()


--Do startup!
local function cWrite( text, fgc, pIndex )
	local old_fgc, isPalette = gpu.getForeground()
	pIndex = ( type( pIndex ) == 'boolean' ) and pIndex or false
	gpu.setForeground( fgc, pIndex )
	term.write(text)
	gpu.setForeground( old_fgc, isPalette )
end -- End of cWrite()


local function cPrint( text, fgc, pIndex )
	local old_fgc, isPalette = gpu.getForeground()
	pIndex = ( type( pIndex ) == 'boolean' ) and pIndex or false
	gpu.setForeground( fgc, pIndex )
	print(text)
	gpu.setForeground( old_fgc, isPalette )
end -- End of cPrint


local function stopTimer()
    event.cancel(theTimer)
end
term.clear()

local arguments_as_a_table = {...}

if (arguments_as_a_table[1] == "wipe") then
    cPrint("Warning! Continuing will erase all of the locally stored content for TrainControl! (configuration and database) Are you sure you want to do this?", 0xB20000)
    if io.read() == "yes" then
        filesystem.remove("/home/databases/config/")
        filesystem.remove("/home/databases/signalDatabase/")
    end

end

cPrint("TrainControl Modem Signal Server (beta) OC-0.1", 0x2E86C1)
if filesystem.exists("/home/databases/config") and filesystem.exists("/home/databases/signalDatabase") then
    config = serialization.unserialize(read_file("databases/config"))
    signalBlocks = serialization.unserialize(read_file("databases/signalDatabase"))
    doControls()
    print("Controlling signals!")

else
    --No config? Okay..enter Remote Configuration Mode.
    print("Configuration not found. Please input server name to recieve a config.")
    local theServerChannel = io.read()
    cPrint("Remote Configuration Mode! Awaiting configuration from "..theServerChannel.."!",0x2E86C1)

    theTimer = event.timer(10, function()
        minitel.rsend(theServerChannel, 1337, encryptMessage(serialization.serialize({protocol = "RequestConfig"})), true)
    end, math.huge)
    print(theTimer)
        --Alright, create a thread and send a new request every 10 seconds.

            event.listen("net_msg", function(event, senderName, port, message)
                print("Got message!")
                message = serialization.unserialize(decryptMessage(message))
                local protocol = getSomethingFromTable(message, "protocol")
               
                if protocol == "RemoteConfigSet" and senderName == theServerChannel then
                    print("Information recieved!")
                    config["serverID"] = senderName
                    saveTableFile("databases/config", config)
                    message["protocol"] = nil
                    signalBlocks = message
                    saveTableFile("databases/signalDatabase", signalBlocks)
                    print("Controlling signals.")
                    stopTimer()
                   
                    doControls()
                    return false
                end
                if protocol == "HelloPing" then
                    print("Responding with ping..but we still need that info.")
                    minitel.rsend(senderName, 1337, encryptMessage(serialization.serialize({protocol = "RequireConfiguration"})))
                end
                
            end)
        
          --[[   local event,senderName,port, message = event.pull()
                message = serialization.unserialize(decryptMessage(message))
                local protocol = getSomethingFromTable(message, "protocol")
            if protocol == "RemoteConfigSet"then
                print("Information recieved!")
                config["serverID"] = senderName
                saveTableFile("databases/config", config)
                signalBlocks = message
                saveTableFile("databases/signalDatabase", signalBlocks)
                event.cancel(theTimer)
                print("Controlling signals.")
                doControls()
            end
            if protocol == "HelloPing" then
                print("Responding with ping..but we still need that info.")
                minitel.rsend(senderName, 1337, encryptMessage(serialization.serialize({protocol = "RequireConfiguration"})))
            end ]]

       





    end
while true do
    os.sleep(0.5)
end
