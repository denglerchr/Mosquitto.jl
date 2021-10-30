using Mosquitto

# connect to a broker, also start loop if Threads.nthreads() > 1
client = Client("test.mosquitto.org")

topic = "test"
message = "Hello World from Julia"
publish(client, topic, message; retain = true)
!client.loop_status && loop(client)

disconnect(client)
lib_cleanup()