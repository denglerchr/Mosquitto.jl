using Mosquitto, Random

function main()

    topic = "test/julia/MQTTv5"

    # Create client and connect to testserver
    client = Client_v5("test.mosquitto.org")

    # Create properties to add to messages
    proplist = PropertyList()
    add_property!(proplist, "content-type", "text/plain")
    add_property!(proplist, "some-property", "stored as user property")

    # Subscribe to receive message
    subscribe(client, topic)
    loop(client)

    # Publish with properties
    publish(
        client,
        topic,
        "Hello World from an MQTTv5 client with properties";
        properties = proplist,
    )
    loop(client; ntimes = 5)

    # Extract all messages to only save the last (probably the one that was sent)
    msg = take!(get_messages_channel(client))
    while !isempty(get_messages_channel(client))
        msg = take!(get_messages_channel(client))
    end

    disconnect(client)

    # Print info on received message
    println("Received message: $(String(msg.payload))")
    println("With properties (as a vector of Pair{String, Vector{UInt8}}):")
    for prop in msg.properties
        println("\t$(prop.name)\t$(String(prop.value))")
    end
end

main()
