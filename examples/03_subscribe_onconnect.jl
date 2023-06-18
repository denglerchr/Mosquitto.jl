# Read 20 messages in topic "test/..." from the public broker test.mosquitto.org
using Mosquitto

# Connect to a broker
client = Client("test.mosquitto.org", 1883)

# subscribe to topic "test" every time the client connects
function onconnect(c)
    # Check if something happened, else return 0
    nmessages = Base.n_avail(get_connect_channel())
    nmessages == 0 && return 0

    # At this point, a connection or disconnection happened
    for i = 1:nmessages
        conncb = take!(get_connect_channel())
        if conncb.val == 1
            println("Connection of client $(conncb.clientptr) successfull (return code $(conncb.returncode)), subscribing to test/#")
            subscribe(c, "test/#")
        elseif conncb.val == 0
            println("Client $(conncb.clientptr) disconnected")
        end
    end
    return nmessages
end


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


# Messages will be put as a tuple in
# the channel Mosquitto.messages_channel.
mrcount = 0
while mrcount < 20
    loop(client) # network loop
    onconnect(client) # check for connection/disconnection
    mrcount += onmessage(mrcount) # check for messages
end

# Close everything
disconnect(client)
loop(client)