using Mosquitto

# defined paths to cafile, certfile, keyfile
include("authfiles/certpaths.jl")

# Create client, but dont connect yet
client = Client()

# Configure tls by providing crt and key files, needs to be done before connecting
tls_set(client, cafile; certfile = certfile, keyfile = keyfile)

# Connect
connect(client, "test.mosquitto.org", 8884)

# Rest as usual, subscribe and publish and read messages
subscribe(client, "test")
publish(client, "test/julia", "hello"; retain = false)
client.loop_status ? sleep(1) : loop(client; ntimes = 10)

nmessages = Base.n_avail(Mosquitto.messages_channel)
for i = 1:nmessages
    msg = take!(Mosquitto.messages_channel) # Tuple{String, Vector{UInt8})
    println("Topic: $(msg.topic)\tMessage: $(String(msg.payload))")
end

disconnect(client)
lib_cleanup()