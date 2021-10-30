using Mosquitto

# import paths to the server ca file (can be downloaded from https://test.mosquitto.org/ )
include("authfiles/certpaths.jl")

# Create client, but dont connect yet
client = Client("", 0; connectme = false)

# Configure tls using the ca certificate
tls_set(client, cafile)

# Connect using username and password
connect(client, "test.mosquitto.org", 8885; username = "rw", password = "readwrite")

# Rest as usual, subscribe and publish and read messages
subscribe(client, "jltest")
publish(client, "jltest", "hello"; retain = false)
client.loop_status ? sleep(1) : loop(client; ntimes = 10)

nmessages = Base.n_avail(Mosquitto.messages_channel)
for i = 1:nmessages
    msg = take!(Mosquitto.messages_channel) # Tuple{String, Vector{UInt8})
    println("Topic: $(msg[1])\tMessage: $(String(msg[2]))")
end

disconnect(client)
lib_cleanup()