# Read 20 messages in topic "test/..." from the public broker test.mosquitto.org
using Mosquitto

function onmessage(nmin, client)
    messages_channel = get_messages_channel(client)
    nmessages = Base.n_avail(messages_channel)
    nmessages == 0 && return 0

    for i = 1:nmessages
        temp = take!(messages_channel)
        println("Message $(nmin + i) of 20:")
        println("\ttopic: $(temp.topic)\tmessage:$(String(temp.payload))")
    end
    return nmessages
end

function main()
    # Connect to a broker
    client = Client("test.mosquitto.org", 1883)
    
    # subscribe to topic "test"
    subscribe(client, "test/#")
    
    # Messages will be put in
    # the clients channel.
    nmessages = 0
    while nmessages<20
        # Take the message on arrival
        loop(client)
        nmessages += onmessage(nmessages, client)
    end

    # Close everything
    disconnect(client)
    loop(client)
end

main()
