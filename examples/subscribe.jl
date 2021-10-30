# This example assumes julia was started with >1 thread
using Mosquitto

# Connect to a broker, also starts loop if Threads.nthreads()>1
client = Client("localhost")

# subscribe to topic "test"
subscribe(client, "test")

# Messages will be put as a tuple in
# the channel Mosquitto.messages_channel.
for i = 1:20
    # Take the message on arrival
    temp = take!(Mosquitto.messages_channel)
    # Do something with the message
    println("Message $i of 20:")
    println("\ttopic: $(temp[1])\tmessage:$(String(temp[2]))")
end

# Close everything
disconnect(client)
lib_cleanup()