# Read 20 messages in topic "test/..." from the public broker test.mosquitto.org
# This example assumes julia was started with >1 thread
# e.g., julia -t 2 subscribe.jl
if Threads.nthreads()<2 
    println("Start julia using atleast 2 threads to run this example:")
    println("julia -t 2 subscribe.jl")
    exit(1)
end

using Mosquitto

# Connect to a broker, also starts loop if Threads.nthreads()>1
client1 = Client("test.mosquitto.org", 1883, startloop = false) # will receive message
client2 = Client("localhost", 1883, startloop = false) # will publish to localhost
client3 = Client("localhost", 1883, startloop = false) # will receive from localhost

# We cant use the loop_start with multiple clients
# Instead we create a task that runs the loops sequentially
publish(client1, "test/julia", "Hello!")
function runloop(n)
    for i = 1:n
        loop(client1; timeout = 100)
        loop(client2; timeout = 100)
        loop(client3; timeout = 100)
    end
    return 0
end
Threads.@spawn runloop(10000)


# subscribe to topic different topics for each client
function subonconnect(c1::Client, c2::Client, c3::Client)
    while true
        conncb = take!(get_connect_channel())
        if conncb.val == 1
            println("$(conncb.clientid): connection successfull")
            conncb.clientid == c1.id && subscribe(c1, "test/#")
            conncb.clientid == c3.id && subscribe(c3, "julia")
        elseif conncb.val == 0
            println("$(conncb.clientid): disconnected")
        else
            println("subonconnect function returning")
            return 0
        end
    end
end
subtask = Threads.@spawn subonconnect(client1, client2, client3)


# Messages will be put as a Message struct
# the channel Mosquitto.messages_channel.
for i = 1:200
    rand()<0.1 && publish(client1, "test/julia", "From client 1"; retain = false)
    # Take the message on arrival
    temp = take!(get_messages_channel())
    # Do something with the message
    if temp.topic == "test/julia"
        println("\ttopic: $(temp.topic)\tmessage:$(String(temp.payload))")
        publish(client2, "julia", "From client 2"; qos = 2)
    elseif temp.topic == "julia"
        println("\ttopic: $(temp.topic)\tmessage:$(String(temp.payload))")
    else
        println("Wrong topic :(")
    end
end


# Close everything
put!(Mosquitto.connect_channel, Mosquitto.ConnectionCB("", UInt8(255), 0))
put!(Mosquitto.messages_channel, Mosquitto.MessageCB("stop", UInt8[])
disconnect(client)
lib_cleanup()