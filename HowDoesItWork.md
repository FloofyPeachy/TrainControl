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
The system communicates with Rednet in ComputerCraft, and Minitel in OpenComputers. They have protocols, as follows:

**HelloPing** Used on startup, sent from the server.

**ConnectionOkay!** Used with Local Signal Servers, used when they get a HelloPing message.

**RequestConfig** Sent from Local Signal Servers that haven't been setup yet, to request a configuration.

**RemoteConfigSet** Sent from the main server with a delicious, juicy, configuration.

**SignalUpdate** Sent from the local signal servers, with signal information. They are sent when `redstone_changed` happens on the local signal servers.

**UpdateSignal** Sent from the main servers to the local signal servers, telling it to update a specific signal.

**UpdateSignalAll** Sent from the main server when it wants a local signal server to update all of the signals.

**W-MTC** Sent from W-MTC Communication Servers, it contains converted W-MTC message information.

**SendWirelessMTC** Sent from main signal servers, provided with a W-MTC message.

Also btw, will they be interoperable between OpenComputers and ComputerCraft? Maybe soon, although I don't think anyone will be using it.

## Signal Numbers to Letters

**0**: Line is clear.

**1**: Blinking yellow. The next signal is yellow.

**2**: Yellow. The next signal is red.

**3**: Red. The block ahead is occupied and you should stop.

## General Operations
First, it starts with the main signal server. It sends to all of the local signal servers (or W-MTC Communications Servers) on startup, a  **HelloPing** to make sure that they are all connected. If not, then the startup process aborts and TrainControl is not started.

If it does go through however, then it starts listening for events.

When a `redstone_changed` event happens from the local signal servers, locally, it sets the aspect to either `0` or `3`. It then sends a **SignalUpdate** to the main signal server. The signal input can come from anywhere, Railcraft Recievers, wire, wireless redstone, it doesn't really matter that much where it comes from.

It gets processed, and does a number of things, like deciding aspects. If there are any yellow/blinking yellow signals, they get sent to their local signal servers using **UpdateSignal**, unless they are from the original signal server that the update was sent from, in that case, it just updates what it's going to send.

Finally, it sends a **UpdateSignalAll** to the signal server that sent the **SignalUpdate**, with information like the signal aspects to set and speed limits for standard MTC.

Once the signal server receives the **UpdateSignalAll**, it updates the signal aspects, whether by using Aspect Controller Blocks (made by yours truly), or some other way. 

With W-MTC messages, they are sent to the W-MTC Communications Server, then processed in the main server, then sent back.

## In conclusion..
~~My signaling system is really cool and its' the best. :sunglasses:~~ My signaling system is kinda complicated but it works really well and I hope more people will use it soon.
