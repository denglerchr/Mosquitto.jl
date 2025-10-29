using Mosquitto

"""
    main(args::AbstractVector{String})

Test for the port 8884 of test.mosquitto.org.
The args vector must contain the file paths for the certificate and key files for this to work.
You can get the files on test.mosquitto.org
"""
function main(args::AbstractVector{String})
    # Checking arguments
    if length(args) < 3
        @warn "Not enough file paths provided for certificate files. Giving it a shot with default filenames..."
        cafile, certfile, keyfile = "mosquitto.org.crt", "client.crt", "client.key"
    else
        cafile, certfile, keyfile = args[1], args[2], args[3]
    end

    # Create client, but dont connect yet
    client = Client()

    # Configure tls by providing crt and key files, needs to be done before connecting
    status = tls_set(client, cafile; certfile = certfile, keyfile = keyfile)
    status != Mosquitto.MosquittoCwrapper.MOSQ_ERR_SUCCESS && error("`tls_set` returned $status")

    # Connect
    connect(client, "test.mosquitto.org", 8884)
    status != Mosquitto.MosquittoCwrapper.MOSQ_ERR_SUCCESS && error("`connect` returned $status")

    # Rest as usual, subscribe and publish and read messages
    subscribe(client, "test/julia")

    n_received = 0
    tnext = now() + Second(1)
    while n_received < 10
        # network loop
        status = loop(client)
        if status != Mosquitto.MosquittoCwrapper.MOSQ_ERR_SUCCESS
            error("`loop` returned $status")
        end

        # check if we have any messages
        while !isempty(get_messages_channel(client))
            msg = take!(get_messages_channel(client))
            n_received += 1
            println("Message $n_received of 10\tTopic: $(msg.topic)\tMessage: $(String(msg.payload))")
        end

        # send a message per second
        if now() > tnext
            tnext += Second(1)
            publish(client, "test/julia", "Hello, so far I have received $n_received messages."; retain = false)
        end
    end

    disconnect(client)
    return 0
end

main(ARGS)