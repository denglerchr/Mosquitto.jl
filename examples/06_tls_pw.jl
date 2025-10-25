using Mosquitto
using Dates

"""
    main(args::AbstractVector{String})

Test for the port 8885 of test.mosquitto.org.
The args vector must contain the file path for the certificate file for this to work.
You can get the file on test.mosquitto.org
"""
function main(args::AbstractVector{String})
    # Checking arguments
    if length(args) < 1
        @warn "Certificate file not provided. Giving it a shot with default filename..."
        cafile = "mosquitto.org.crt"
    else
        cafile = args[1]
    end

    # Create client, but dont connect yet
    client = Client()

    # Configure tls by providing crt and key files, needs to be done before connecting
    status = tls_set(client, cafile)
    status != Mosquitto.MosquittoCwrapper.MOSQ_ERR_SUCCESS && error("`tls_set` returned $status")

    # Connect
    status = connect(client, "test.mosquitto.org", 8885; username = "rw", password = "readwrite")
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