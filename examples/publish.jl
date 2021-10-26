using Mosquitto

client = Client("localhost")

topic = "test"
message = "Hello World"
publish(client, topic, message)

disconnect(client)
lib_cleanup()