using Mosquitto

client = Client("localhost")

topic = "test"
channel = Channel{Any}(10)
subscribe!(client, topic, channel)
take!(channel)

unsubscribe(client, topic)
disconnect(client)
