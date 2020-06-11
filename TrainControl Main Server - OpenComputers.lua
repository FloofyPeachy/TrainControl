--PeachMaster's MTC and Digital Interlocking System: A system for MTC and W-MTC, but this one is for standard MTC
--OpenComputers Rewrite

--Hi! you are not supposted to access this file.
--...unless you know what you're doing. I mean, why are you doing this? This file isn't really for editing.
--You get what you get and you don't throw a fit. That's what my kindergarden teacher said.

-- Menu API provided by cyanisaac and ProjectB, licensed under the MIT license.
--JSON API provided by ElvishJerricco. 
--Initalize all the things! 
--Initalize signalblocks
--TrainControl 1.1 
--Use one channel instead of multiple for signal communications
--TrainControl 1.2 
--Use rednet instead, security is the same as modems
--Maybe modules? 

--TrainControl 1.3 OpenComputers Rewrite



--Required APIs
local event = require("event")
local filesystem = require("filesystem")
local thread = require("thread")
local serialization = require("serialization")
local comp = require("component")
local term = require("term")
local minitel = require("minitel")
local json = require("json")
local interwebs = require("internet")
local inspect = require("inspect")

--Haha, woah woah woah.  Before we get to the APIs, let's add the GUI API.

local arguments = {...}

local GUI = require("GUI2")
local version = "TrainControl OC-0.1"

--GUI stuff. May be removed if things don't work out. :( Also, let's define everything.
local leWorkspace = GUI.workspace()
leWorkspace:addChild(GUI.panel(1, 1, leWorkspace.width, leWorkspace.height, 0x2D2D2D))

local theMainContainer = leWorkspace:addChild(GUI.container(1,1, leWorkspace.width, leWorkspace.height,0x2D2D2D))
local splashScreenContainer = theMainContainer:addChild(GUI.container(1,1, leWorkspace.width, leWorkspace.height,0x2D2D2D))

splashScreenContainer:addChild(GUI.label(1,1, leWorkspace.width, leWorkspace.height, 0xFFFFFF, "PeachMaster's MTC and Digital Interlocking System (now for OpenComputers!)")):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_CENTER)
splashScreenContainer:addChild(GUI.label(1,1, leWorkspace.width, leWorkspace.height, 0xFFFFFF, version)):setAlignment(GUI.ALIGNMENT_HORIZONTAL_RIGHT, GUI.ALIGNMENT_VERTICAL_BOTTOM)


local webhookURL = ""
--Required Functions

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

local function sendDiscordWebhook(theMessage)
    print(json.encode(theMessage))
   interwebs.request(webhookURL, json.encode(theMessage), {["Content-Type"] = "application/json", ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.138 Safari/537.36"})


end

local function saveTableFile(path, watchuwant)
    write_file(path, watchuwant)
end

local function loadTableFile(path)
    return serialization.unserialize(read_file(path))
end

--Required files
local signalBlocks = serialization.unserialize(read_file("databases/signalDatabase"))
local computerDatabase = serialization.unserialize(read_file("databases/computerDatabase"))
local statistics = serialization.unserialize(read_file("databases/statistics"))
local config = {}
local loadedModules = {}
--Required components
local modem = comp.modem
local gpu = comp.gpu
--local gui = require("gui") -- Replaced later?


--Setup function
--Todo, create setup later
local function setup() 
    local createdConfig = {}
    term.clear()   
    print("Please set a name for this system for identification (ex railroad/division name): ")
    local systemName = io.read()
    createdConfig["SystemName"] = systemName
    print("What kind of communications will be used? (1 via Modem, 2 Bundled Redstone)")
    createdConfig["SignalConnectionType"] = io.read()
    print("Use MTC? (true/false)")
    createdConfig["UseMTC"] = io.read()
    print("Allow modules? (true/false)")
    createdConfig["AllowModules"] = io.read()
    print("Setup complete! TrainControl will start after you press any key.")
    config = createdConfig
    saveTableFile("databases/config", createdConfig)
    os.sleep(2)
end



--Functions that need to be after the requires

local function decryptMessage(leMessage) --Not implimented, just return
    return leMessage
end

local function encryptMessage(leMessage) --Not implimented, just return
    return leMessage
end

local function sendModem(leMessage,hostname)
    minitel.rsend(hostname, 1337, encryptMessage(leMessage))
end

local function justSendSomething(leMessage, hostname)
    minitel.rsend(hostname, 1337, encryptMessage(leMessage))
end

--Helper functions, makes code more easier to read. :D
local function getSignalName(theSignal) 
    return getSomethingFromTable(theSignal, "signalName")
end

local function getSignal(theSignalName)
    return getSomethingFromTable(signalBlocks, theSignalName)
end

local function getNextSignal(theSignal) 
    return getSomethingFromTable(theSignal, "next")
end

local function getPreviousSignal(theSignal) 
    return getSignal(getSomethingFromTable(theSignal, "prev"))
end

local function getPreviousSignalName(theSignal) 
    return getSomethingFromTable(theSignal, "prev")
end

local function getPreviousSignalByName(theSignal) 
    return getSomethingFromTable(getSignal(), "prev")
end



local function getSignalStatus(theSignal)
    return getSomethingFromTable(theSignal, "status")
end

local function setSignalStatus(theSignal, theStatus)
    return true
end

local function getSignalHostname(theSignal)
    return getSomethingFromTable(theSignal, "computerID" )
end

local function updateStatistics(field, value) -- Funct, add, update, remove
    statistics[field] = value
    saveTableFile("databases/statistics", statistics)
end

local function controlSignals()
    --This mainly controls the signals. It's pretty important.
    signalDatabase = loadTableFile("databases/signalDatabase")
        --e26a8730
    if config.SignalConnectionType == "1" then  -- In OpenComputers, this is Modem instead of Rednet
        print(event)
        local event,senderName,port,message,proto,extra1,extra2= event.pull() 
        print(event,senderName,port,message,protocol)
        message = decryptMessage(message)
        local signalsFromResponse = {}
        print(event)
        if event == "net_msg" then
            message = serialization.unserialize(message)
            proto = message["protocol"]
           
            --[[ 
                Oh, this part is pretty important. It describes internal signal aspects.
                0: Green. Line is clear, dude.
                1. Blinking yellow. Watch out, the next signal is yellow. You might want to prepare to stop at the next signal.
                2. Yellow. Watch out dude, train in the next block.
                3. STAWP! Block Occupied! AAAAAAAAAAAAAAA
             ]]
        if proto == "SignalUpdate" then
            local theSignals = getSomethingFromTable(message, "theSignals")
            for k, v in pairs(theSignals) do
              --  if getPreviousSignal(signalBlocks[k]).status ~= 3 or getPreviousSignal(signalBlocks[k]).status ~= 2 then
                signalBlocks[k].status = theSignals[k].status
                signalsFromResponse[k] = {}
                signalsFromResponse[k].status = theSignals[k].status
                print("Signals updated!")
            end -- end of for k, v in pairs(theSignals) do
               -- end
            --Do the aspects and determine if it's yellow.
            for k, v in pairs(theSignals) do
                print(k.." is there a previous signal,  "..tostring((getPreviousSignalName(signalBlocks[k]) ~= "none")))
             if getPreviousSignalName(signalBlocks[k]) ~= "none" then
                local previousSignal = getPreviousSignal(signalBlocks[k])
                print("Signal status for "..getPreviousSignalName(signalBlocks[k]).." is " .. getSignalStatus(previousSignal))
                if getSignalStatus(v) == 3 then
                    --Alright, let's do some checking.
                        print(k.." prev: "..getSignalStatus(signalBlocks[getPreviousSignalName(signalBlocks[k])]) )
                        print(getSignalStatus(signalBlocks[getPreviousSignalName(signalBlocks[k])])~=3)
                        if getSignalStatus(signalBlocks[getPreviousSignalName(signalBlocks[k])]) ~= 3 then
                            print(getSignalStatus(signalBlocks[getPreviousSignalName(signalBlocks[k])]))
                            signalBlocks[getPreviousSignalName(signalBlocks[k])].status = 2
                    
                            print(getSignalStatus(signalBlocks[getPreviousSignalName(signalBlocks[k])]))
                            if getSomethingFromTable(signalBlocks[getPreviousSignalName(signalBlocks[k])], "computerID") == senderName then
                                --Oh. Okay, we don't need to send a signal update because we can just add it to the one that's coming up. Contiue on.
                                print("Just updating the signal aspect for "..getPreviousSignalName(signalBlocks[k])..", we don't need to send something because the signal servers are the same.")
                            else
                                sendModem(serialization.serialize({signal = getSignalName(previousSignal), status = getSignalStatus(previousSignal), protocol = "UpdateSignal"}), getSignalHostname(previousSignal))
                                print("Sending a yellow signal update to "..getSignalName(previousSignal)..".")
                            end
                        end
                end
                --Find a previous previous signal

                if getPreviousSignalName(signalBlocks[k]) ~= "none" and getPreviousSignalName(getPreviousSignal(signalBlocks[k])) ~= "none" then
                    local previousPreviousSignal = getPreviousSignal(getPreviousSignal(signalBlocks[k]))
                    local previousSignal = getPreviousSignal(signalBlocks[k])
                    print(getSignalStatus(previousPreviousSignal))
                    if getSignalStatus(previousSignal) == 2 then
                        --Alright, let's do some checking.
                            if getSignalStatus(signalBlocks[getPreviousSignalName(previousSignal)]) ~= 3 then
                                signalBlocks[getPreviousSignalName(previousSignal)].status = 1
                                
                                print(getSignalStatus(signalBlocks[getPreviousSignalName(previousSignal)]))
                                if getSomethingFromTable(signalBlocks[getPreviousSignalName(previousSignal)], "computerID") == senderName then
                                    --Oh. Okay, we don't need to send a signal update because we can just add it to the one that's coming up. Contiue on.
                                    print("Just updating the signal aspect for "..getSignalName(previousPreviousSignal)..", we don't need to send something because the signal servers are the same.")
                                else
                                    sendModem(serialization.serialize({signal = getSignalName(previousPreviousSignal), status = getSignalStatus(previousPreviousSignal), protocol = "UpdateSignal"}), getSignalHostname(previousSignal))
                                    print("Sending a yellow signal update to "..getSignalName(previousPreviousSignal)..".")
                                end
                            end
                    end
                end

            end 
            
            --Determine the speed limits.

        end -- end of for k, v in pairs(theSignals) do
            for k, v in pairs(theSignals) do
                local thisSignal = signalBlocks[k]
                local nextSignal = getNextSignal(thisSignal)
                if nextSignal ~= "none" then
                    nextSignal = getNextSignal(thisSignal)
                end
    
                if nextSignal ~= nil and (config["UseMTC"] == 1 or config["UseMTC"] == 2) then
                    if nextSignal.status == 3 then
                        signalsFromResponse[k].nextSpeedLimit = 0
                        signalsFromResponse[k].xStopPoint = nextSignal.posX
                        signalsFromResponse[k].yStopPoint = nextSignal.posY
                        signalsFromResponse[k].zStopPoint = nextSignal.posZ
                    end
                end
    
                --Determine next speed limit.
                if nextSignal ~= nil and nextSignal.speedLimit ~= thisSignal.speedLimit and (config["UseMTC"] == 1 or config["UseMTC"] == 2) then
                    signalsFromResponse[k].speedLimit = signalBlocks[k].speedLimit
                    signalsFromResponse[k].nextSpeedLimit = nextSignal.speedLimit
                    signalsFromResponse[k].xChangeSpeed = nextSignal.posX
                    signalsFromResponse[k].yChangeSpeed = nextSignal.posY
                    signalsFromResponse[k].zChangeSpeed = nextSignal.posZ
                else
                    signalsFromResponse[k].speedLimit = signalBlocks[k].speedLimit
                end

            end 
                --Alright. All of the statues is set, so let's confirm to make sure the right signals are sent.
                for k, v in pairs(theSignals) do
                    signalsFromResponse[k].status = signalBlocks[k].status

                end

            --To implement: Switches and stuff, don't forget about this Peachy :P

            for file in pairs(loadedModules) do
                loadedModules[file]()
                signalsUpdated(event, senderName,port,message,proto,extra1,extra2)
           end

        end --End of SignalUpdate

        if proto == "RequestConfig" then
            local theComputer = getSomethingFromTable(computerDatabase, senderName)
            if theComputer ~= nil then
                local sendTable = {}
                for k, v in pairs(theComputer) do
                    sendTable[k] = v
                end
                sendTable["protocol"] = "RemoteConfigSet"
                justSendSomething(serialization.serialize(sendTable), senderName)
                print("Remote configuration sent to "..senderName)
            end

        end -- End of RequestConfig
        --Now, calculate W-MTC information.

        if proto == "W-MTC" then
            print("Got a W-MTC message!")
            local send = {}
            --It comes in fresh in a Lua table, just for your consumption!
            message = decryptMessage(message)
            local funct = getSomethingFromTable(message["theMessage"], "funct")
            print(funct)
            if funct == "attemptconnection" then
                print("Why are we here?")
                --Send placeholder information because we don't know where they are.
                send["theMessage"] = {}
                send["theMessage"]["funct"] = "startlevel2"
                send["theMessage"]["speedLimit"] = 15
                send["theMessage"]["nextSpeedLimit"] = 0
                send["theMessage"]["mtcStatus"] = 1
                print("Train ID: "..message["trainID"])
                print("Function is attempting a conection, just send it some static info before we figure out where they are.")
            
            send["protocol"] = "SendWirelessMTC"
            send["sendTo"]  = message["trainID"]
            print(funct=="attemptconnection")
            minitel.send(senderName, 1337, serialization.serialize(encryptMessage(send)))
            print("Sending W-MTC message back.")
        end

        if funct == "update" then
            --Alright, well, they have the signal block, so let's give them the relavant info.
            local theSignal = getSignal(message["theMessage"]["signalBlock"])
            local nextSignal = signalBlocks[getNextSignal(theSignal)]
            send["protocol"] = "SendWirelessMTC"
            send["sendTo"]  = message["trainID"]
            send["theMessage"] = {}
            send["theMessage"]["funct"] = "response"
            if theSignal ~= nil then
                if nextSignal ~= nil then
                    print(nextSignal["status"])
                    if nextSignal.status == 3  then
                        send["theMessage"]["nextSpeedLimit"]  = 0
                        send["theMessage"]["stopSoon"] = true
                        send["theMessage"]["xStopPoint"] = nextSignal.posX
                        send["theMessage"]["yStopPoint"] = nextSignal.posY
                        send["theMessage"]["zStopPoint"] = nextSignal.posZ
                        print(nextSignal.posX)
                        print(nextSignal.posY)
                        print(nextSignal.posZ)
                    else
                        send["theMessage"]["xStopPoint"] = "reset"
                    end
                    if  nextSignal.speedLimit ~= theSignal.speedLimit then
                        send["theMessage"]["speedLimit"] = theSignal.speedLimit
                        send["theMessage"]["speedChangeSoon"] = true
                        send["theMessage"]["nextSpeedLimit"] = nextSignal.speedLimit
                        send["theMessage"]["xNextSpeedLimit"] = nextSignal.posX
                        send["theMessage"]["yNextSpeedLimit"] = nextSignal.posY
                        send["theMessage"]["zNextSpeedLimit"] = nextSignal.posZ
                    else
                        send["theMessage"]["xNextSpeedLimit"] = "reset"
                        send["theMessage"]["speedLimit"] = theSignal.speedLimit
                    end
                end
            end
            print(serialization.serialize(encryptMessage(send)))
            minitel.send(senderName, 1337, serialization.serialize(encryptMessage(send)))
            print("Sent signal data to W-MTC.")
        end
    end
        --..we got everything? Good! Send it to the signals.
        if message.source ~= "Terminal" and proto ~= "RequestConfig" and proto == "SignalUpdate" then
            --   local send = doEncrypt({funct = "updateSignalStatus", to = key})
            local sendTable = {}
            print("Signals to be sent (and their values)")
               for k, v in pairs(signalsFromResponse) do
                    print(k..":"..serialization.serialize(v))
               end
               --sendTable["sendTo"] = getSomethingFromTable(message, "theSignal")
               --modem.send(senderID, encryptMessage(sendTable), "UpdateSignalAll")
               sendTable["protocol"] = "UpdateSignalAll"
               sendTable["theSignals"] = signalsFromResponse
               minitel.rsend(senderName, 1337, serialization.serialize(encryptMessage(sendTable)))
               print("Sent the updated signals back to "..senderName..".")
               --Oh also, update the stats. That's pretty important.
               updateStatistics("signalsUpdated", tonumber(statistics["signalsUpdated"]) + 1)
          -- modem.transmit(config["ModemChannel"], config["ModemChannel"], doEncrypt({funct = "updateSignalStatus", signalStatus = getSomethingFromTable(signalBlocks, response.source).status, to = getSomethingFromTable(signalBlocks, response.source).name, isWMTCOkay = getSomethingFromTable(signalBlocks, response.source).isWMTCOkay}))
           end -- End of response

        end -- End of eveents?
    
       for file in pairs(loadedModules) do
            loadedModules[file]()
            doEvent(event, senderName,port,message,proto,extra1,extra2)
       end
    end -- End of SignalConnectionType == 1


end -- End of controlSignalls()


local function startup() -- Test to make sure everything is working right.
    if config.SignalConnectionType == "1" then
        local lastTest
        for key,value in pairs( computerDatabase ) do
            local send = encryptMessage({protocol = "HelloPing"})
            
            
            print("Attempting connection to.."..key.."!")
            minitel.send(key, 1337, serialization.serialize(send))
            local theEvent,senderName,_,message = event.pull(10, "net_msg")
            
            if theEvent ~= nil then
                local theMessage = decryptMessage(serialization.unserialize(message))
                local protocol = theMessage["protocol"]
                if protocol == "ConnectionOkay!" then
                    print(key.." has came back with an OK response!")
                    lastTest = senderName
                end
                if protocol == "RequireConfiguration" then
                    print(key.." requires a configuration, but we will handle it later.")
                end

                    
            else
                
                print("Attempt to reach "..key.." failed, maybe the computerID is set incorrectly or it's too far away?")
                return false, "Attempt to reach "..key.." failed, maybe the computerID is set incorrectly or it's too far away?"
            end
            
        end
        return true, "Nothing bad happened!"
    end
    
end -- End of startup()

local function cWrite( text, fgc, pIndex )
	local old_fgc, isPalette = gpu.getForeground()
	pIndex = ( type( pIndex ) == 'boolean' ) and pIndex or false
	gpu.setForeground( fgc, pIndex )
	print(text)
	gpu.setForeground( old_fgc, isPalette )
end -- End of cWrite()


term.clear()

if filesystem.exists("/home/databases/config") then
    config = serialization.unserialize(read_file("databases/config"))
else
    setup()
end

local arguments = {...}
if arguments[1] == "gui" then
    splashScreenContainer:addChild(GUI.label(1,1, leWorkspace.width, leWorkspace.height, 0xFFFFFF, "This installation is for: "..getSomethingFromTable(config, "SystemName"))):setAlignment(GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_BOTTOM)
    leWorkspace:draw()
    os.sleep(2)
    theMainContainer:removeChildren(1,1)
   --[[  local startupScreenContainer = theMainContainer:addChild(GUI.container(1,1, leWorkspace.width, leWorkspace.height,0x2D2D2D))
    startupScreenContainer:addChild(GUI.panel(10, 10, leWorkspace.width - 40, leWorkspace.height - 40, 0x880000)):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_CENTER)
    leWorkspace:draw() ]]

    local startupWindow = leWorkspace:addChild(GUI.window(90, 6, 60, 20))
    startupWindow:addChild(GUI.panel(1, 1, leWorkspace.width, leWorkspace.height, 0xF0F0F0))
    startupWindow:addChild(GUI.text(3, 2, 0x2D2D2D, "Regular window example"))
    leWorkspace:draw()
    leWorkspace:start()
end

cWrite("PeachMaster's MTC and Digital Interlocking System (now for OpenComputers!)", 0x2E86C1)
cWrite("TrainControl OC-0.1", 0x2E86C1)
cWrite("This installation is for: "..getSomethingFromTable(config, "SystemName"), 0x2E86C1)

local theStartupResult, reply = startup() 
--Skip
if theStartupResult then
    print("Connection to all Local Signal Servers successful!")
--Find and add modules.
cWrite("Loading modules..", 0x2E86C1)
if config["AllowModules"] == "true" then
    for file in filesystem.list("/home/modules/") do
        if not filesystem.isDirectory(file) then
            local thing = loadfile("/home/modules/"..file)
            loadedModules[file] = thing
            loadedModules[file]()
            start()
        end

    end
end

cWrite("Modules loaded successfully!", 0x2E86C1)
cWrite("Controlling signals now! ", 0x2E86C1)
while true do
controlSignals()
end

else
    print("Didn't execute right? What happened?")
   --[[  sendDiscordWebhook(
    {
        username = "TrainControl",
        content = "Error!",
        embeds = {
            {
                color = 13369344,
                title = "TrainControl Error!",
                description = "An error occured. "..reply.." This happened on "..getSomethingFromTable(config, "SystemName").."! <@208869516199854080>, please do something about it!",
                footer = {
                    text = "Btw whoever sees this, this took too long to make because Discord is racist against Java useragents"
                },
                },
        },
}) ]]
end
