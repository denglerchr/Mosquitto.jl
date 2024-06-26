# Mosquitto.jl

A wrapper around the [Mosquitto](https://mosquitto.org/) C Api. MQTT v3.1.1 and MQTT 5 functionalities are wrapped.

## Installation
This package is registered. To add it to your Julia installation/project, type
`]add Mosquitto` or `import Pkg; Pkg.add("Mosquitto")`.
The supported Mosquitto client binary (v2.0.15) should be downloaded automatically.

## Basic Usage

Apart from the descriptions below, exampled can be found in the [examples](examples/) folder

### Connect to a broker

```julia
using Mosquitto
client = Client("test.mosquitto.org", 1883)
```

Create a client (MQTT v3.1.1) using the ip and port of the broker. 
Use ?Mosquitto.Client for information on client settings.

### Publish a message
```julia
topic = "test"
message = "hello world"
publish(client, topic, message)

# Perform network loop
loop(client)
```

A message can be of type string, or of a type that can be converted to a Vector{UInt8} using reinterpret. Publishing might not happen until you call *loop(client)*.

### Subscribe to a topic
```julia
topic = "test"
subscribe(client, topic)
```
The subscription will vanish on disonnect. To automatically subscribe each time the client connects, you can subscribe after a connection was detected. Please look at the example [examples/03_subscribe_onconnect.jl](examples/03_subscribe_onconnect.jl) 

### Simple example

This example scripts will
1) create a connection to a public broker
2) subscribes to the topic "jltest"
3) publish 2 messages to the same topic "jltest"
4) read and print the messages.
Note that the script might print 3 messages if a message for that topic was "retained".

```julia
using Mosquitto

# 1)
client = Client("test.mosquitto.org", 1883)

# 2)
topic = "jltest"
subscribe(client, topic)

# 3)
# Send 2 messages, first one will remain in the broker an be received on new connect
publish(client, topic, "Hi from Julia"; retain = true)
publish(client, topic, "Another message"; retain = false)

# Lets call the network loop a few times, to make sure messages are sent/received
loop(client; timeout = 500, ntimes = 10)

# 4)
msg_channel = get_messages_channel(client)
while !isempty(msg_channel)
    msg = take!(msg_channel) # Tuple{String, Vector{UInt8})
    println("Topic: $(msg.topic)\tMessage: $(String(msg.payload))")
end
```

## Advanced Usage and Notes

### Callbacks on messages or connection/disconnection
While the mosquitto C library requires callback functions, this package uses Channels to indicate the receiving of a message or the connection/disconnection to/from a broker. You should `take!(channel)` on these, possibly after checking for the number of available messages if not run in a separate thread. Each client contains 3 channels (one is reserved for internal use) of which the 2 important ones can be accessed via:
* `get_messages_channel(client)`
* `get_connect_channel(client)`

To awaid blocking when channels are full due to too many messages, the channels can be treated similar as circular buffers, i.e., first item is removed if the channel is full and a new item is pushed. The options to activate this behavior are keyword options of the Client constructor
* `autocleanse_message_channel`
* `autocleanse_connect_channel`

### Running the loop continuously
The network loop needs to be called continuously in order to send receive messages. The simplest way to do this
is to call the *loop(client)* function regularly. 

As a first alternative, the functions *loop_start(client)* and *loop_stop(client)* can be called to handle this in another C-thread.

As a second alternative, the mosquitto library provides a *Mosquitto.loop_forever(client)* function that is wrapped as well. This background task will run until *disconnect(client)* is called and then return. As such, the message and connect events should be handled in an @async task. For an example usage, see [examples/07_loop_forever.jl](examples/07_loop_forever.jl). Due to reports of instability, it is recommended to use *loop(client)* instead of *Mosquitto.loop_forever(client)*.

### Authentication
You find examples in the example folder for how to use TLS connections and user/password authetication. Currently bad credentials do not lead to any error or warning, your messages will just not be sent and you will not receive any messages.

### Using MQTT v5
Instead of creating a `Client` object, create a `Client_v5` object. Most functions like `publish`, `subscribe`, `loop` etc are overloaded to work the same way as for the v3.1.1 client, except some of them accept an optional keyword argument `properties`.
This keyword argument can be set to a `PropertyList`. See the example [examples/09_MQTT5_properties.jl](examples/09_MQTT5_properties.jl) for an example on how to use properties, or consult `?PropertyList`.

### Advanced example

```julia
# Read 20 messages in topic "test/..." from the public broker test.mosquitto.org
# Different from the previous example, the client will resubscribe to its topic every time it connects to the broker
using Mosquitto

# Connect to a broker using tls and username/password authetication.
# The CA certificate can be downloaded from the mosquitto page https://test.mosquitto.org/ssl/mosquitto.org.crt
# The connect function must be used only after tls_set.
client = Client(; id = "JuliaClient1")
const cafilepath = "..." # add path to ca certificate here
tls_set(client, cafilepath)
connect(client, "test.mosquitto.org", 8885; username = "rw", password = "readwrite")


# Subscribe to topic "test" every time the client connects
# To know if there was a connection/disconnection, the channel
# get_connect_channel(client) is used.
function onconnect(c)
    nmessages = 0

    # Treat all events
    while !isempty(get_connect_channel(c))
        conncb = take!(get_connect_channel(c))
        nmessages += 1
        if conncb.val == 1
            println("Connection of client $(client.id) successfull, subscribing to test/#")
            subscribe(c, "test/#")
        elseif conncb.val == 0
            println("Client $(client.id) disconnected")
        end
    end
    return nmessages
end


# Print a message if it is received.
# To know if a message was received, we check
# the channel msg_channel = get_messages_channel(client).
function onmessage(mrcount, client)
    nmessages = 0
    msg_channel = get_messages_channel(client)

    # At this point, a message was received, lets process it
    while !isempty(msg_channel)
        temp = take!(msg_channel)
        nmessages += 1
        println("Message $(mrcount+nmessages):")
        message = String(temp.payload)
        length(message) > 20 && (message = message[1:18]*"...")
        println("\ttopic: $(temp.topic)\tmessage:$(message)")
    end
    return nmessages
end


function main()
    # We trigger the loop manually until we have received at least
    # 20 messages
    mrcount = 0
    while mrcount < 20
        loop(client) # network loop
        onconnect(client) # check for connection/disconnection
        mrcount += onmessage(mrcount, client) # check for messages
    end

    # Disconnect the client
    disconnect(client)
    loop(client)
end


main()
```
