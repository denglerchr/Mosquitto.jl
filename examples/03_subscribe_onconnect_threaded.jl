# Read 20 messages in topic "test/..." from the public broker test.mosquitto.org
# Different from example 02, the client will resubscribe to its topic every time it connects to the broker
# This example assumes julia was started with >1 thread
# e.g., julia -t 2 subscribe.jl
if Threads.nthreads()<2 
    println("Start julia using atleast 2 threads to run this example:")
    println("julia -t 2 subscribe.jl")
    exit(1)
end

using Mosquitto

# Connect to a broker, also starts loop if Threads.nthreads()>1
client = Client("test.mosquitto.org", 1883)

# subscribe to topic "test" every time the client connects
function subonconnect(c)
    while true
        conncb = take!(get_connect_channel())
        if conncb.val == 1
            println("Connection of client $(conncb.clientptr) successfull, subscribing to test/#")
            subscribe(c, "test/#")
        elseif conncb.val == 0
            println("Client $(conncb.clientptr) disconnected")
        else
            println("Subonconnect function returning")
            return 0
        end
    end
end
Threads.@spawn subonconnect(client)

# Messages will be put as a tuple in
# the channel Mosquitto.messages_channel.
for i = 1:50
    # Take the message on arrival
    temp = take!(get_messages_channel())
    # Do something with the message
    println("Message $i of 50:")
    message = String(temp.payload)
    length(message) > 15 && (message = message[1:13]*"...")
    println("\ttopic: $(temp.topic)\tmessage:$(message)")
end

# Close everything
put!(Mosquitto.connect_channel, Mosquitto.ConnectionCB("", UInt8(255), 0))
disconnect(client)
lib_cleanup()