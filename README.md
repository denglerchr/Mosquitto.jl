# Mosquitto.jl

A wrapper around the Mosquitto C Api. The package provides easy to use MQTT client functionality.

## Package Status
* **Linux + Julia v1.6.x** has trouble when using multiple threads. You need to upgrade to 1.7 or use single thread with manual "loop" calls for that specific configuration.
MQTT v5 features like properties are not yet implemented. If you have the need for those, feel free to add an request on Github.

## Installation
* Install the mosquitto library
Follow the instructions at https://mosquitto.org/download/
* Download the julia package
`]add https://github.com/denglerchr/Mosquitto.jl`

## Basic Usage

### Connect to a broker

```julia
using Mosquitto
client = Client("test.mosquitto.org", 1883)
```

Create a client using the ip and port of the broker. If you use >1 julia thread, the network loop will start immediately.
Use ?Mosquitto.Client for information on client settings.

### Publish a message
```julia
topic = "test"
message = "hello world"
publish(client, topic, message)

# only necessary if network loop isnt running in seprate thread
!client.status.loop_status && loop(client)
```

A message can be of type string, or of a type that can be converted to a Vector{UInt8} using reinterpret. If you do not use multiple threads and *loop_start(client)*, publishing might not happen until you call *loop(client)*.

### Subscribe to a topic
```julia
topic = "test"
subscribe(client, topic)
```
The subscription will vanish on disonnect. To automatically reconnect, you should subscribe after a connection was detected. Please look at the example *examples/03_subscribe_conconnect.jl* 

### Simple example

This example scripts will
1) create a connection to a public broker
2) subscribes to the topic "jltest"
3) publish 2 messages to the same topic "jltest"
4) read and print the messages.
Note that the script might print 3 messages if a message for that topic is "retained".

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

# lets wait to be sure to receive something
# or call the loop during that time, to make sure stuff is sent/received
client.status.loop_status ? sleep(3) : loop(client; timeout = 500, ntimes = 10)

# 4)
nmessages = Base.n_avail(Mosquitto.messages_channel)
for i = 1:nmessages
    msg = take!(Mosquitto.messages_channel) # Tuple{String, Vector{UInt8})
    println("Topic: $(msg.topic)\tMessage: $(String(msg.payload))")
end
```

Before closing Julia, you should properly clean up the session using
```julia
disconnect(client)
lib_cleanup()
```

## Advanced Usage and Notes

### Callbacks on messages or connection/disconnection
While the mosquitto C library requires callback functions, this package uses Channels to indicate the receiving of a message or the connection/disconnection to/from a broker. You should `take!(channel)` on these, possibly after checking for the number of available messages if not run in a separate thread. The two channels can be accessed via:
* `get_messages_channel()` or `Mosquitto.messages_channel`
* `get_connect_channel()` or `Mosquitto.connect_channel`

### Use a single threads or multiple threads
For simplicity of use, the network loop is executed in parallel when using multiple threads. This can in some cases lead to problems, e.g., when using multiple clients, as running multiple loops in parallel is not supported currently. Therefore, client loops should be run in sequence, see *examples/multiple_clients.jl* for an example.


### Authentication
You find examples in the example folder for how to use TLS connections and user/password authetication. Currently bad credentials do not lead to any error or warning, your messages will just not be sent and you will not receive any messages.

### Advanced example

```julia
# Read 20 messages in topic "test/..." from the public broker test.mosquitto.org
# Different from the previous example, the client will resubscribe to its topic every time it connects to the broker
using Mosquitto

# Connect to a broker using tls and username/password authetication.
# The CA certificate can be downloaded from the mosquitto page https://test.mosquitto.org/ssl/mosquitto.org.crt
# The connect function will not start a network loop in parallel, loop is triggered manually later.
client = Client()
const cafilepath = ... # add path to ca certificate here
tls_set(client, cafilepath)
connect(client, "test.mosquitto.org", 8885; username = "rw", password = "readwrite")

# Subscribe to topic "test" every time the client connects
# To know if there was a connection/disconnection, the channel Mosquitto.connect_channel
# or get_connect_channel() is used.
function onconnect(c)
    # Check if something happened, else return 0
    nmessages = Base.n_avail(get_connect_channel())
    nmessages == 0 && return 0

    # At this point, a connection or disconnection happened
    for i = 1:nmessages
        conncb = take!(get_connect_channel())
        if conncb.val == 1
            println("Connection of client $(conncb.clientptr) successfull, subscribing to test/#")
            subscribe(c, "test/#")
        elseif conncb.val == 0
            println("Client $(conncb.clientptr) disconnected")
        end
    end
    return nmessages
end


# Print a message if it is received.
# To know if a message was received, we use the Mosquitto.messages_channel
# or get_messages_channel().
function onmessage(mrcount)
    # Check if something happened, else return 0
    nmessages = Base.n_avail(get_messages_channel())
    nmessages == 0 && return 0

    # At this point, a message was received, lets process it
    for i = 1:nmessages
        temp = take!(get_messages_channel())
        println("Message $(mrcount+i):")
        message = String(temp.payload)
        length(message) > 20 && (message = message[1:18]*"...")
        println("\ttopic: $(temp.topic)\tmessage:$(message)")
    end
    return nmessages
end


# We trigger the loop manually until we have received at least
# 20 messages
mrcount = 0
while mrcount < 20
    loop(client) # network loop
    onconnect(client) # check for connection/disconnection
    mrcount += onmessage(mrcount) # check for messages
end

# Close everything
disconnect(client)
lib_cleanup()
```