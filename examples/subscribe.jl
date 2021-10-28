using Mosquitto

client = Client("localhost")

topic = "test"
#channel = Channel{Any}(10)
subscribe(client, topic)
#take!(channel)
for i = 1:10
    loop(client; timeout = 2000)
    println(i)
end

unsubscribe(client, topic)
disconnect(client)
lib_cleanup()