using Mosquitto, Test, Random

topic = "jltest"*randstring(5)
message = [1, 2, 3]

client_v5 = Client_v5()
testproplist = create_property_list("Hello", "World")

while true
will_set(client_v5, "topic", "I disconnected due to some issue"; properties = testproplist)

MosquittoCwrapper.property_check_all(MosquittoCwrapper.CMD_PUBLISH, testproplist.mosq_prop.x)
will_clear(client_v5) # clears properties??
MosquittoCwrapper.property_check_all(MosquittoCwrapper.CMD_PUBLISH, testproplist.mosq_prop.x)
end