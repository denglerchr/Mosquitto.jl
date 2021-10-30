# Mosquitto.jl

A wrapper around the Mosquitto C Api. The package provides easy to use MQTT client functionality.

## Package Status
* **Linux + Julia v1.6.3** has trouble when using multiple threads. You need to upgrade to 1.7 or use single thread with manual "loop" calls for that specific configuration.

### What works
* connecting to a broker
* publishing messages
* subscribing to topics
* authetication using tls and/or username and password

### Todos
* v5 features like properties

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
!client.loop_status && loop(client)
```

A message can be of type string, or of a type that can be converted to a Vector{UInt8} using reinterpret. If you do not use multiple threads and *loop_start(client)*, publishing might not happen until you call *loop(client)*.

### Subscribe to a topic
```julia
topic = "test"
subscribe(client, topic)
```

### Complete example

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
client.loop_status ? sleep(3) : loop(client; timeout = 1000, ntimes = 5)

# 4)
nmessages = Base.n_avail(Mosquitto.messages_channel)
for i = 1:nmessages
    msg = take!(Mosquitto.messages_channel) # Tuple{String, Vector{UInt8})
    println("Topic: $(msg[1])\tMessage: $(String(msg[2]))")
end
```

Before closing Julia, you should properly clean up the session using
```julia
disconnect(client)
lib_cleanup()
```

## Advanced Usage
You find examples in the example folder for how to use TLS connections and user/password authetication. Currently bad credentials do not lead to any error or warning, your messages will just not be sent and you will not receive any messages.