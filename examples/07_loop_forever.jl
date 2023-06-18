# Read 20 messages in topic "test/..." from the public broker test.mosquitto.org
# This script uses the loop_forever, which is blocking, therefore this needs to run with at least 2 Threads
if Threads.nthreads() < 2
    println("This script required at least 2 threads to run correctly")
    exit(1)
end

using Mosquitto, ThreadPools
const messages_until_disconnect = 200

# Connect to a broker
client = Client("test.mosquitto.org", 1883)

# subscribe to topic "test" every time the client connects. Return on disconnect.
function onconnect(client)
    disconnect = false
    while !disconnect
        conncb = take!(get_connect_channel())
        if conncb.val == 1
            println("Connection of client $(conncb.clientptr) successfull ($(conncb.returncode)), subscribing to test/#")
            subscribe(client, "test/#")
        elseif conncb.val == 0
            println("Client $(conncb.clientptr) disconnected ($(conncb.returncode))")
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


# message and connection handling on thread 1 asynchronously
@async onconnect(client)
@async onmessage(client)

# Loop on thread 2 (blocking) until disconnect is called
looptask = ThreadPools.@tspawnat 2 (@info "Started loop on thread $(Threads.threadid())"; loop_forever(client)) # will run until disconnect is called
wait(looptask)

println("Done")