# Read 20 messages in topic "test/..." from the public broker test.mosquitto.org
# This script uses the loop_forever instead of calling loop() manually.
# loop_forever return only when the client disconnects
using Mosquitto
const messages_until_disconnect = 200

# Connect to a broker
client = Client("test.mosquitto.org", 1883)

# subscribe to topic "test" every time the client connects. Return on disconnect.
function onconnect(client)
    disconnect = false
    while !disconnect
        conncb = take!(get_connect_channel(client))
        if conncb.val == 1
            println("Connection of client $(client.id) successfull ($(conncb.returncode)), subscribing to test/#")
            subscribe(client, "test/#")
        elseif conncb.val == 0
            println("Client $(client.id) disconnected ($(conncb.returncode))")
            disconnect = true
        end
    end
    return 0
end

# Print a message each time, one is received. Disconnect after
# *messages_until_disconnect* messages
function onmessage(client)
    msgcount = 0
    while msgcount < messages_until_disconnect
        temp = take!(get_messages_channel(client))
        msgcount += 1
        println("Message $(msgcount):")
        message = String(temp.payload)
        length(message) > 20 && (message = message[1:18]*"...")
        println("\ttopic: $(temp.topic)\tmessage:$(message)")
    end
    disconnect(client) # this will later make loop_forever return
    return msgcount
end


# message and connection handling on thread 1 asynchronously
@async onconnect(client)
@async onmessage(client)

# Loop until disconnect is called in the onmessage function
rc = loop_forever(client)

println("Done")