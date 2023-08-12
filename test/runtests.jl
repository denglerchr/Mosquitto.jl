using Mosquitto, Test, Random

topic = "jltest"*randstring(5)
message = [1, 2, 3]

client = Client("test.mosquitto.org", 1883)

@testset "Unauthenticated" begin
    @test subscribe(client, topic) == Mosquitto.MosquittoCwrapper.MOSQ_ERR_SUCCESS
    @test loop(client) == Mosquitto.MosquittoCwrapper.MOSQ_ERR_SUCCESS
    while !isempty(get_messages_channel(client))
        # empty channel
        take!(get_messages_channel(client))
    end
    @test publish(client, topic, message; retain = false) == Mosquitto.MosquittoCwrapper.MOSQ_ERR_SUCCESS
    loop(client, ntimes = 10)
    @test Base.n_avail(get_messages_channel(client)) == 1
    if Base.n_avail(get_messages_channel(client)) >= 1
        @test Array(reinterpret(Int, take!(get_messages_channel(client)).payload)) == message
    end
    @test disconnect(client) == Mosquitto.MosquittoCwrapper.MOSQ_ERR_SUCCESS
    loop(client)
end


client = Client()

@testset "Last Will" begin
    @test will_set(client, "topic", "I disconnected due to some issue") == Mosquitto.MosquittoCwrapper.MOSQ_ERR_SUCCESS
    @test will_clear(client) == Mosquitto.MosquittoCwrapper.MOSQ_ERR_SUCCESS
end

@testset "Authenticated" begin
    @test connect(client, "test.mosquitto.org", 1884; username = "rw", password = "readwrite") == Mosquitto.MosquittoCwrapper.MOSQ_ERR_SUCCESS
    @test subscribe(client, topic) == Mosquitto.MosquittoCwrapper.MOSQ_ERR_SUCCESS
    @test loop(client) == Mosquitto.MosquittoCwrapper.MOSQ_ERR_SUCCESS
    while !isempty(get_messages_channel(client))
        # empty channel
        take!(get_messages_channel(client))
    end
    @test publish(client, topic, message; retain = false) == Mosquitto.MosquittoCwrapper.MOSQ_ERR_SUCCESS
    loop(client, ntimes = 5)
    loop(client; ntimes = 2, timeout = 5000)
    @test Base.n_avail(get_messages_channel(client)) == 1
    if Base.n_avail(get_messages_channel(client)) >= 1
        @test Array(reinterpret(Int, take!(get_messages_channel(client)).payload)) == message
    end
    @test disconnect(client) == Mosquitto.MosquittoCwrapper.MOSQ_ERR_SUCCESS
    loop(client)
end

@testset "Properties" begin
    
    proplist = create_property_list("Hello", "World")
    add_property!(proplist, "payload-format-indicator", UInt8(1))
    add_property!(proplist, "receive-maximum", UInt16(200))
    add_property!(proplist, "message-expiry-interval", UInt32(200))
    add_property!(proplist, "subscription-identifier", UInt32(200))
    add_property!(proplist, "authentication-data", UInt8[1, 2, 3])
    add_property!(proplist, "content-type", "hdf5")
    add_property!(proplist, "FOO", "BAR")

    properties = read_property_list(proplist)

    @test properties[1].name == "Hello"
    @test String(properties[1].val) == "World"
    @test properties[1].type == Mosquitto.MosquittoCwrapper.MQTT_PROP_TYPE_STRING_PAIR

    @test properties[7].name == "content-type"
    @test String(properties[7].val) == "hdf5"
    @test properties[7].prop == Mosquitto.MosquittoCwrapper.MQTT_PROP_CONTENT_TYPE
    @test properties[7].type == Mosquitto.MosquittoCwrapper.MQTT_PROP_TYPE_STRING

    ## Check for memory leaks, TODO retest, due to Julia 1.9 GC bug
    GC.gc()
    freemem = Sys.free_memory()
    for i = 1:300_000
        proplist = create_property_list("payload-format-indicator", UInt8(1))
        add_property!(proplist, "receive-maximum", UInt16(200))
        add_property!(proplist, "message-expiry-interval", UInt32(200))
        add_property!(proplist, "subscription-identifier", UInt32(200))
        add_property!(proplist, "authentication-data", UInt8[1, 2, 3])
        add_property!(proplist, "content-type", "hdf5")
        add_property!(proplist, "FOO", "BAR")
    
        properties = read_property_list(proplist)
    end
    GC.gc()
    @test Sys.free_memory()-freemem < 100
end

