# Read 20 messages in topic "test/..." from the public broker test.mosquitto.org
# This script uses the loop_forever, which is blocking, therefore this needs to run with at least 2 Threads
if Threads.nthreads() < 2
    println("This script required at least 2 threads to runcorrectly")
    exit(1)
end

using Mosquitto
const messages_until_disconnect = 300

# Connect to a broker, but dont start network loop.
# We will trigger the network loop manually here using the loop function
client = Client("test.mosquitto.org", 1883)

# subscribe to topic "test" every time the client connects. Return on disconnect.
function onconnect(client)
    disconnect = false
    while !disconnect
        conncb = take!(get_connect_channel())
        if conncb.val == 1
            println("Connection of client $(conncb.clientptr) successfull, subscribing to test/#")
            subscribe(client, "test/#")
        elseif conncb.val == 0
            println("Client $(conncb.clientptr) disconnected")
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
        temp = take!(get_messages_channel())
        msgcount += 1
        println("Message $(msgcount):")
        message = String(temp.payload)
        length(message) > 20 && (message = message[1:18]*"...")
        println("\ttopic: $(temp.topic)\tmessage:$(message)")
    end
    disconnect(client)
    return msgcount
end


# Messages will be put as a tuple in
# the channel Mosquitto.messages_channel.
@async onconnect(client)
@async onmessage(client)
temp = Threads.@spawn loop_forever(client) # will run until disconnect is called
wait(temp)
println("Done")