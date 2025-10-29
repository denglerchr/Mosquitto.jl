using Mosquitto, Test, Random

topic = "jltest"*randstring(5)
message = [1, 2, 3]

client = Client("test.mosquitto.org", 1883)

@testset "Unauthenticated" begin
    ##########################
    # This test subscribes to random topic on a public broker
    # then publishes a messages and sees if it is returned
    ##########################
    @test subscribe(client, topic)[1] == Mosquitto.MosquittoCwrapper.MOSQ_ERR_SUCCESS
    @test loop(client) == Mosquitto.MosquittoCwrapper.MOSQ_ERR_SUCCESS
    while !isempty(get_messages_channel(client))
        # empty channel
        take!(get_messages_channel(client))
    end
    @test publish(client, topic, message; retain = false)[1] == Mosquitto.MosquittoCwrapper.MOSQ_ERR_SUCCESS
    loop(client, ntimes = 10)
    @test Base.n_avail(get_messages_channel(client)) == 1
    if Base.n_avail(get_messages_channel(client)) >= 1
        @test Array(reinterpret(Int, take!(get_messages_channel(client)).payload)) == message
    end
    @test disconnect(client) == Mosquitto.MosquittoCwrapper.MOSQ_ERR_SUCCESS
    loop(client)

    ##########################
    # Same test with loop_start and loop_stop
    ##########################
    connect(client, "test.mosquitto.org", 1883)
    @test loop_start(client) == Mosquitto.MosquittoCwrapper.MOSQ_ERR_SUCCESS
    @test subscribe(client, topic)[1] == Mosquitto.MosquittoCwrapper.MOSQ_ERR_SUCCESS
    while !isempty(get_messages_channel(client))
        # empty channel
        take!(get_messages_channel(client))
    end
    @test publish(client, topic, message; retain = false)[1] == Mosquitto.MosquittoCwrapper.MOSQ_ERR_SUCCESS
    sleep(1) #  give the message some time to be received
    @test Base.n_avail(get_messages_channel(client)) == 1
    if Base.n_avail(get_messages_channel(client)) >= 1
        @test Array(reinterpret(Int, take!(get_messages_channel(client)).payload)) == message
    end
    @test disconnect(client) == Mosquitto.MosquittoCwrapper.MOSQ_ERR_SUCCESS
    loop_stop(client) == Mosquitto.MosquittoCwrapper.MOSQ_ERR_SUCCESS # this test would fail, no idea whats wrong, maybe related to https://github.com/eclipse/mosquitto/issues/2905 ?
end


client = Client()


@testset "Last Will" begin
    @test will_set(client, "topic", "I disconnected due to some issue") == Mosquitto.MosquittoCwrapper.MOSQ_ERR_SUCCESS
    @test will_clear(client) == Mosquitto.MosquittoCwrapper.MOSQ_ERR_SUCCESS
end

@testset "Authenticated" begin
    @test connect(client, "test.mosquitto.org", 1884; username = "rw", password = "readwrite") == Mosquitto.MosquittoCwrapper.MOSQ_ERR_SUCCESS
    @test subscribe(client, topic)[1] == Mosquitto.MosquittoCwrapper.MOSQ_ERR_SUCCESS
    @test loop(client) == Mosquitto.MosquittoCwrapper.MOSQ_ERR_SUCCESS
    while !isempty(get_messages_channel(client))
        # empty channel
        take!(get_messages_channel(client))
    end
    @test publish(client, topic, message; retain = false)[1] == Mosquitto.MosquittoCwrapper.MOSQ_ERR_SUCCESS
    loop(client, ntimes = 5)
    loop(client; ntimes = 2, timeout = 5000)
    @test Base.n_avail(get_messages_channel(client)) == 1
    if Base.n_avail(get_messages_channel(client)) >= 1
        @test Array(reinterpret(Int, take!(get_messages_channel(client)).payload)) == message
    end
    @test disconnect(client) == Mosquitto.MosquittoCwrapper.MOSQ_ERR_SUCCESS
    loop(client)
end




client_v5 = Client_v5()
testproplist = PropertyList("Hello", "World")

@testset "Last Will v5" begin
    @test will_set(client_v5, "topic", "I disconnected due to some issue"; properties = testproplist) == Mosquitto.MosquittoCwrapper.MOSQ_ERR_SUCCESS
    @test will_clear(client_v5) == Mosquitto.MosquittoCwrapper.MOSQ_ERR_SUCCESS 
end

@testset "Properties" begin
    
    proplist = PropertyList()
    add_property!(proplist, "Hello", "World")
    add_property!(proplist, "payload-format-indicator", UInt8(1))
    add_property!(proplist, "receive-maximum", UInt16(200))
    add_property!(proplist, "message-expiry-interval", UInt32(200))
    add_property!(proplist, "subscription-identifier", UInt32(200))
    add_property!(proplist, "authentication-data", UInt8[1, 2, 3])
    add_property!(proplist, "content-type", "hdf5")
    add_property!(proplist, "FOO", "BAR")
    

    properties = read_property_list(proplist)

    @test properties[1].name == "Hello"
    @test String(properties[1].value) == "World"
    @test properties[1].type == Mosquitto.MosquittoCwrapper.MQTT_PROP_TYPE_STRING_PAIR

    @test properties[7].name == "content-type"
    @test String(properties[7].value) == "hdf5"
    @test properties[7].prop == Mosquitto.MosquittoCwrapper.MQTT_PROP_CONTENT_TYPE
    @test properties[7].type == Mosquitto.MosquittoCwrapper.MQTT_PROP_TYPE_STRING

    # Same tests with explicit Property definition
    proplist = PropertyList()
    property = Property("Hello", "World")
    add_property!(proplist, property)
    property = Property("payload-format-indicator", UInt8(1))
    add_property!(proplist, property)
    property = Property("receive-maximum", UInt16(200))
    add_property!(proplist, property)
    property = Property("message-expiry-interval", UInt32(200))
    add_property!(proplist, property)
    property = Property("subscription-identifier", UInt32(200))
    add_property!(proplist, property)
    property = Property("authentication-data", UInt8[1, 2, 3])
    add_property!(proplist, property)
    property = Property("content-type", "hdf5")
    add_property!(proplist, property)
    property = Property("FOO", "BAR")
    add_property!(proplist, property)

    properties = read_property_list(proplist)

    @test properties[1].name == "Hello"
    @test String(properties[1].value) == "World"
    @test properties[1].type == Mosquitto.MosquittoCwrapper.MQTT_PROP_TYPE_STRING_PAIR

    @test properties[7].name == "content-type"
    @test String(properties[7].value) == "hdf5"
    @test properties[7].prop == Mosquitto.MosquittoCwrapper.MQTT_PROP_CONTENT_TYPE
    @test properties[7].type == Mosquitto.MosquittoCwrapper.MQTT_PROP_TYPE_STRING

end

@testset "Unauthenticated V5" begin
    @test connect(client_v5, "test.mosquitto.org", 1883) == Mosquitto.MosquittoCwrapper.MOSQ_ERR_SUCCESS
    @test subscribe(client_v5, topic)[1] == Mosquitto.MosquittoCwrapper.MOSQ_ERR_SUCCESS
    @test loop(client_v5) == Mosquitto.MosquittoCwrapper.MOSQ_ERR_SUCCESS
    while !isempty(get_messages_channel(client_v5))
        # empty channel
        take!(get_messages_channel(client_v5))
    end
    @test publish(client_v5, topic, message; retain = false, properties = testproplist)[1] == Mosquitto.MosquittoCwrapper.MOSQ_ERR_SUCCESS
    loop(client_v5, ntimes = 10)
    @test Base.n_avail(get_messages_channel(client_v5)) == 1
    if Base.n_avail(get_messages_channel(client_v5)) >= 1
        msg = take!(get_messages_channel(client_v5))
        @test Array(reinterpret(Int, msg.payload)) == message
        @test length(msg.properties) == 1
        if length(msg.properties) == 1
            @test msg.properties[1].name == "Hello"
            @test String(msg.properties[1].value) == "World"
        end
    end
    @test disconnect(client_v5) == Mosquitto.MosquittoCwrapper.MOSQ_ERR_SUCCESS
    loop(client_v5)
end

@testset "Misc" begin
    @test tls_insecure_set(client, true) == Mosquitto.MosquittoCwrapper.MOSQ_ERR_SUCCESS
end

## Check for memory leaks
# GC.gc()
# while true
#     proplist = create_property_list("payload-format-indicator", UInt8(1))
#     add_property!(proplist, "receive-maximum", UInt16(200))
#     add_property!(proplist, "message-expiry-interval", UInt32(200))
#     add_property!(proplist, "subscription-identifier", UInt32(200))
#     add_property!(proplist, "authentication-data", UInt8[1, 2, 3])
#     add_property!(proplist, "content-type", "hdf5")
#     add_property!(proplist, "FOO", "BAR")
#     #properties = read_property_list(proplist)
# end
# GC.gc()
