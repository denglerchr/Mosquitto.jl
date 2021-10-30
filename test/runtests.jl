using Mosquitto, Test, Random

topic = "jltest"*randstring(5)
message = [1, 2, 3]

client = Client("test.mosquitto.org", 1883)

@testset "General" begin
    Threads.nthreads()>1 && @test client.loop_status == 1
    Threads.nthreads()==1 && @test client.loop_status == 0
    @test loop_stop(client) == 0
end

@testset "Unauthenticated" begin
    @test subscribe(client, topic) == 0
    @test loop(client) == 0
    while !isempty(Mosquitto.messages_channel)
        # empty channel
        take!(Mosquitto.messages_channel)
    end
    @test publish(client, topic, message; retain = false) == 0
    loop(client, ntimes = 5)
    loop(client; ntimes = 2, timeout = 5000)
    @test Base.n_avail(Mosquitto.messages_channel) == 1
    if Base.n_avail(Mosquitto.messages_channel) >= 1
        @test Array(reinterpret(Int, take!(Mosquitto.messages_channel)[2])) == message
    end
    @test disconnect(client) == 0
end


client = Client("", 0; connectme = false)

@testset "Authenticated" begin
    @test connect(client, "test.mosquitto.org", 1884; username = "rw", password = "readwrite") == 0
    @test subscribe(client, topic) == 0
    @test loop(client) == 0
    while !isempty(Mosquitto.messages_channel)
        # empty channel
        take!(Mosquitto.messages_channel)
    end
    @test publish(client, topic, message; retain = false) == 0
    loop(client, ntimes = 5)
    loop(client; ntimes = 2, timeout = 5000)
    @test Base.n_avail(Mosquitto.messages_channel) == 1
    if Base.n_avail(Mosquitto.messages_channel) >= 1
        @test Array(reinterpret(Int, take!(Mosquitto.messages_channel)[2])) == message
    end
    @test disconnect(client) == 0
end

lib_cleanup()
