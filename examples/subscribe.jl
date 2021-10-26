using Mosquitto

client = Client("localhost")

topic = "test"
#channel = Channel{Any}(10)
subscribe!(client, topic)
#take!(channel)

unsubscribe(client, topic)
disconnect(client)
lib_cleanup()