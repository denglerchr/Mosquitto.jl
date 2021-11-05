# Read 20 messages in topic "test/..." from the public broker test.mosquitto.org
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

# subscribe to topic "test"
subscribe(client, "test/#")

# Messages will be put in
# the channel Mosquitto.messages_channel.
for i = 1:20
    # Take the message on arrival
    temp = take!(Mosquitto.messages_channel)
    # Do something with the message
    println("Message $i of 20:")
    println("\ttopic: $(temp.topic)\tmessage:$(String(temp.payload))")
end

# Close everything
disconnect(client)
lib_cleanup()