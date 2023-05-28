# Read 20 messages in topic "test/..." from the public broker test.mosquitto.org
using Mosquitto

# Connect to a broker, also starts loop if Threads.nthreads()>1
client = Client("test.mosquitto.org", 1883)

# subscribe to topic "test"
subscribe(client, "test/#")

function onmessage(nmin)
    nmessages = Base.n_avail(Mosquitto.messages_channel)
    nmessages == 0 && return 0

    for i = 1:nmessages
        temp = take!(Mosquitto.messages_channel)
        println("Message $(nmin + i) of 20:")
        println("\ttopic: $(temp.topic)\tmessage:$(String(temp.payload))")
    end
    return nmessages
end

# Messages will be put in
# the channel Mosquitto.messages_channel.
nmessages = 0
while nmessages<20
    # Take the message on arrival
    loop(client)
    nmessages += onmessage(nmessages)
end

# Close everything
disconnect(client)
loop(client)