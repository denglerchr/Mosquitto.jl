using Mosquitto

# connect to a broker, also start loop if Threads.nthreads() > 1
client = Client("localhost")

topic = "test"
message = "Hello World"
publish(client, topic, message)

disconnect(client)
lib_cleanup()