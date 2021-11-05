using Mosquitto

# import paths to the server ca file (can be downloaded from https://test.mosquitto.org/ )
include("authfiles/certpaths.jl")

# Create client, but dont connect yet
client = Client()

# Configure tls using the ca certificate, needs to be done before connecting
tls_set(client, cafile)

# Connect using username and password
connect(client, "test.mosquitto.org", 8885; username = "rw", password = "readwrite")

# Rest as usual, subscribe and publish and read messages
subscribe(client, "test")
publish(client, "test/julia", "hello"; retain = false)
client.status.loop_status ? sleep(1) : loop(client; ntimes = 10)

nmessages = Base.n_avail(Mosquitto.messages_channel)
for i = 1:nmessages
    msg = take!(Mosquitto.messages_channel) # Tuple{String, Vector{UInt8})
    println("Topic: $(msg.topic)\tMessage: $(String(msg.payload))")
end

disconnect(client)
lib_cleanup()