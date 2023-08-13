using Mosquitto

client_v5 = Client_v5()
testproplist = create_property_list("Hello", "World")
MosquittoCwrapper.property_check_all(MosquittoCwrapper.CMD_PUBLISH, testproplist.mosq_prop.x)

connect(client_v5, "localhost", 1883)
subscribe(client_v5, "JuliaBugTest")
loop(client_v5)

publish(client_v5, "JuliaBugTest", "Hello World"; retain = false, properties = testproplist)
loop(client_v5, ntimes = 5)

get_messages_channel(client_v5)

msg = take!(get_messages_channel(client_v5))

String(msg.payload) == "Hello World"
msg.properties

if length(msg.properties) == 1
    msg.properties[1].name == "Hello"
    String(msg.properties[1].value) == "World"
end