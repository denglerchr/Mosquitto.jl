# Connect to 3 clients, 1 on the test server of mosquitto and 2 on localhost (requires a broker to run on localhost:1883)
# We run this only with manual loop execution, as multiple client with threaded network loop are currently not supported.
# What this script does:
# The client 1 will subscribe to messages, and every time a message is received in the correct topic test/julia
# client 2 will publish a message to localhost which is again received by client 3

using Mosquitto

# Connect to multiple brokers
client1 = Client("test.mosquitto.org", 1883) # will receive message
client2 = Client("localhost", 1883) # will publish to localhost
client3 = Client("localhost", 1883) # will receive from localhost

# subscribe to a topic on connection event
function subonconnect(client::Client, topic::String)
    # check channel, if there is something todo
    while !isempty(get_connect_channel(client))
        conncb = take!(get_connect_channel(client))
        if conncb.val == 1
            println("$(client.id): connection successfull")
            subscribe(client, topic)
        elseif conncb.val == 0
            println("$(conncb.clientid): disconnected")
        end
    end
    return 0
end

# Replicate messages from client1 to client2
function forwardmessages(client1, client2)
    while !isempty(get_messages_channel(client1))
        temp = take!(get_messages_channel(client1))
        # Do something with the message
        if temp.topic == "test/julia"
            msg = String(temp.payload)
            println("Message from client $(client.id)")
            println("\ttopic: $(temp.topic)\tmessage:$msg")

            # republish
            publish(client2, "julia", "From client 2: $msg"; qos = 2)
        end
    end
    return 0
end

function printmessages(client)
    while !isempty(get_messages_channel(client))
        temp = take!(get_messages_channel(client))
        
        msg = String(temp.payload)
        println("Message from client $(client.id)")
        println("\ttopic: $(temp.topic)\tmessage:$msg")
    end
    return 0
end

# Messages will be put as a Message struct
# the channel Mosquitto.messages_channel.
for i = 1:200
    loop(client1; timeout = 100)
    loop(client2; timeout = 100)
    loop(client3; timeout = 100)

    subonconnect(client1, "test/#")
    subonconnect(client3, "julia")
    forwardmessages(client1, client2)
    printmessages(client3)
    rand()<0.1 && publish(client1, "test/julia", "From client 1"; retain = false)
end


# Close everything
disconnect(client1)
disconnect(client2)
disconnect(client3)