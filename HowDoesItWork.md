# How to TrainControl (or, how does it work)
You are that interested in my work? Okay. Read up here, get knowledeged.

## Systems

There are **2** essential parts for TrainControl to function properly. They are:

**Main Signal Server**:
This is where you run the main traincontrol program. It stores the signals, and provides  an interface for railroad owners to work with.

**Local Signal Server**:
The local signal server is where the trackside signals are at and interfaced with. One server usually holds a couple of signals.

*Optionally..*

**W-MTC Communications Server**: This is where W-MTC messages are received from a radio and sent to the server, or vice versa. 

## Communication
The signals communicate with Rednet in ComputerCraft, and Minitel in OpenComputers. They have protocols, as follows:

**HelloPing** Used on startup, sent from the server.

**ConnectionOkay!** Used with Local Signal Servers, used when they get a HelloPing message.

**RequestConfig** Sent from Local Signal Servers that haven't been setup yet, to request a configuration.

**RemoteConfigSet** Sent from the main server with a delicious, juicy, configuration.

**SignalUpdate** Sent from the local signal servers, with signal information. They are sent when `redstone_changed` happens on the local signal servers.

**UpdateSignal** Sent from the main servers to the local signal servers, telling it to update a specific signal.

**UpdateSignalAll** Sent from the main server when it wants a local signal server to update all of the signals.

**W-MTC** Sent from W-MTC Communication Servers, it contains converted W-MTC message information.

**SendWirelessMTC** Sent from main signal servers, provided with a W-MTC message.

