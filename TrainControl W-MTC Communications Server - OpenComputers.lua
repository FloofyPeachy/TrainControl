--W-MTC Communications Server
--PeachMaster's MTC and Digital Interlocking System (TrainControl)

--Translates W-MTC messages to TrainControl messages and vice cersa.

--Required APIs
local event = require("event")
local filesystem = require("filesystem")
local thread = require("thread")
local serialization = require("serialization")
local comp = require("component")
local term = require("term")
local json = require("json")
local minitel = require("minitel")
local wirelessMTCRadio

local gpu = comp.gpu
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

local function saveTableFile(path, watchuwant)
    write_file(path, watchuwant)
end

local function loadTableFile(path)
    return serialization.unserialize(read_file(path))
end

local config = {}

local function cWrite( text, fgc, pIndex )
	local old_fgc, isPalette = gpu.getForeground()
	pIndex = ( type( pIndex ) == 'boolean' ) and pIndex or false
	gpu.setForeground( fgc, pIndex )
	print(text)
	gpu.setForeground( old_fgc, isPalette )
end -- End of cWrite()


local function decryptMessage(leMessage) --Not implimented, just return
    return leMessage
end

local function encryptMessage(leMessage) --Not implimented, just return
    return leMessage
end

local function doWirelessMTC() 

    event.listen("net_msg", function(event, senderName, port, message, protocol)
        if message ~= nil then
            if senderName == getSomethingFromTable(config, "serverID") then
                print(message)
            message = serialization.unserialize(message)
            protocol = getSomethingFromTable(message, "protocol")
            print("Net msg!")
           
            if protocol == "SendWirelessMTC" then
                print("PRotoocl; SneWirelessMTC")
                print(message["sendTo"]==nil)
                print(message["theMessage"]==nil)
                wirelessMTCRadio.sendMessage(message["sendTo"], json.encode(message["theMessage"]))
                print("Sent W-MTC message!")
            end
    
            if protocol == "HelloPing" then
                minitel.send(senderName, 1337, encryptMessage(serialization.serialize({protocol = "ConnectionOkay!"})))
                print("Hello server! Responding back.")
            end
        end
        end
    end)
    
    event.listen("radio_message", function(event, nodeAddress, something, trainID, something, message, system)
        print("Radio_message")
        local sendTable = {}
        sendTable["protocol"] = "W-MTC"
        print("Here..")
        print("Event: "..event)
        print("NodeAddress: "..nodeAddress)
        print("? "..something)
        print("TrainID: "..trainID)
        print("message: "..message)
        print("System: "..system)
        sendTable["theMessage"] = json.decode(message)
        sendTable["trainID"] = trainID
        print("Here!")
        minitel.send(config["serverID"], 1337, encryptMessage(serialization.serialize(sendTable)))
        print("Got MTC message and sent it to the server.")

        
    end)
   

end

term.clear()
cWrite("TrainControl W-MTC Communications Server (beta) OC-0.1", 0x2E86C1)
--Alright..what does this do exactly?
if filesystem.exists("/home/databases/config") then
    config = serialization.unserialize(read_file("databases/config"))
else
    print("Please insert main server: ")
    local theServerID = io.read()
    config["serverID"] = theServerID
    saveTableFile("/home/databases/config",config)
    print("Configuration written!")
end

for address, name in comp.list("wirelessMTCRadio", false) do
    wirelessMTCRadio = comp.proxy(address)
    print("Found a radiO!")
end
print(wirelessMTCRadio==nil)
if wirelessMTCRadio == nil then
    error("Wireless Radio not found. Maybe it's not attached?")
end

print("Starting server!")
print(wirelessMTCRadio.activate())
doWirelessMTC()

while true do
    os.sleep(0.5)
end

