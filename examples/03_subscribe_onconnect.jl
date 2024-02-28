# Read 20 messages in topic "test/..." from the public broker test.mosquitto.org
using Mosquitto

# Connect to a broker
client = Client("test.mosquitto.org", 1883)

# subscribe to topic "test" every time the client connects
function onconnect(client)
    # Check if something happened, else return 0
    nmessages = Base.n_avail(get_connect_channel(client))
    nmessages == 0 && return 0

    # At this point, a connection or disconnection happened
    for _ = 1:nmessages
        conncb = take!(get_connect_channel(client))
        if conncb.val == 1
            topic = "test/#"
            println("Connection of client $(client.id) successfull (return code $(conncb.returncode)), subscribing to $(topic)")
            subscribe(client, topic)
        elseif conncb.val == 0
            println("Client $(client.id) disconnected")
        end
    end
    return nmessages
end


function onmessage(mrcount, client)
    # Check if something happened, else return 0
    nmessages = Base.n_avail(get_messages_channel(client))
    nmessages == 0 && return 0

    # At this point, a message was received, lets process it
    for i = 1:nmessages
        temp = take!(get_messages_channel(client))
        println("Message $(mrcount+i):")
        message = String(temp.payload)
        length(message) > 20 && (message = message[1:18]*"...")
        println("\ttopic: $(temp.topic)\tmessage:$(message)")
    end
    return nmessages
end


# Messages will be put as a tuple in
# the channel Mosquitto.messages_channel.
mrcount = 0
while mrcount < 20
    loop(client) # network loop
    onconnect(client) # check for connection/disconnection
    mrcount += onmessage(mrcount, client) # check for messages
end

# Close everything
disconnect(client)
loop(client)
