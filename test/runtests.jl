using Mosquitto, Test, Random

topic = "jltest"*randstring(5)
message = [1, 2, 3]

client = Client("test.mosquitto.org", 1883)

@testset "Unauthenticated" begin
    @test subscribe(client, topic) == Mosquitto.MOSQ_ERR_SUCCESS
    @test loop(client) == Mosquitto.MOSQ_ERR_SUCCESS
    while !isempty(get_messages_channel(client))
        # empty channel
        take!(get_messages_channel(client))
    end
    @test publish(client, topic, message; retain = false) == Mosquitto.MOSQ_ERR_SUCCESS
    loop(client, ntimes = 10)
    @test Base.n_avail(get_messages_channel(client)) == 1
    if Base.n_avail(get_messages_channel(client)) >= 1
        @test Array(reinterpret(Int, take!(get_messages_channel(client)).payload)) == message
    end
    @test disconnect(client) == Mosquitto.MOSQ_ERR_SUCCESS
    loop(client)
end


client = Client()

@testset "Authenticated" begin
    @test connect(client, "test.mosquitto.org", 1884; username = "rw", password = "readwrite") == Mosquitto.MOSQ_ERR_SUCCESS
    @test subscribe(client, topic) == Mosquitto.MOSQ_ERR_SUCCESS
    @test loop(client) == Mosquitto.MOSQ_ERR_SUCCESS
    while !isempty(get_messages_channel(client))
        # empty channel
        take!(get_messages_channel(client))
    end
    @test publish(client, topic, message; retain = false) == Mosquitto.MOSQ_ERR_SUCCESS
    loop(client, ntimes = 5)
    loop(client; ntimes = 2, timeout = 5000)
    @test Base.n_avail(get_messages_channel(client)) == 1
    if Base.n_avail(get_messages_channel(client)) >= 1
        @test Array(reinterpret(Int, take!(get_messages_channel(client)).payload)) == message
    end
    @test disconnect(client) == Mosquitto.MOSQ_ERR_SUCCESS
    loop(client)
end