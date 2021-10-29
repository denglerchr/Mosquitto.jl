using Mosquitto, Test, Random

topic = "jltest"*randstring(5)
message = [1, 2, 3]

client = Client("localhost", 1883)

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
    @test publish(client, topic, message; retain = true) == 0
    loop(client)
    sleep(0.1)
    loop(client)
    @test Base.n_avail(Mosquitto.messages_channel) == 1
    if Base.n_avail(Mosquitto.messages_channel) >= 1
        @test Array(reinterpret(Int, take!(Mosquitto.messages_channel)[2])) == message
    end
end
