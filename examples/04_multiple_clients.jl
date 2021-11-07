# Connect to 3 clients, 1 on the test server of mosquitto and 2 on localhost (requires a broker to run on localhost:1883)
# We run this only with manual loop execution, as multiple client with threaded network loop are currently not supported.
# What this script does:
# The client 1 will subscribe to messages, and every time a message is received in the correct topic test/julia
# client 2 will publish a message to localhost which is again received by client 3

using Mosquitto

# Connect to a broker, also starts loop if Threads.nthreads()>1
client1 = Client("test.mosquitto.org", 1883, startloop = false) # will receive message
client2 = Client("localhost", 1883, startloop = false) # will publish to localhost
client3 = Client("localhost", 1883, startloop = false) # will receive from localhost

# subscribe to topic different topics for each client
function subonconnect(c1::Client, c2::Client, c3::Client)
    # check channel, if there is something todo
    nmessages = Base.n_avail(get_connect_channel())
    nmessages == 0 && return 0
    for i = 1:nmessages
        conncb = take!(get_connect_channel())
        if conncb.val == 1
            println("$(conncb.clientptr): connection successfull")
            conncb.clientptr == c1.cptr.mosc && subscribe(c1, "test/#")
            conncb.clientptr == c3.cptr.mosc && subscribe(c3, "julia")
        elseif conncb.val == 0
            println("$(conncb.clientptr): disconnected")
        end
    end
    return 0
end

# What to do if there is a message
function onmessage(c1, c2)
    rand()<0.1 && publish(c1, "test/julia", "From client 1"; retain = false)
    
    nmessages = Base.n_avail(get_messages_channel())
    nmessages == 0 && return 0
    for i = 1:nmessages
        temp = take!(get_messages_channel())
        # Do something with the message
        if temp.topic == "test/julia"
            println("\ttopic: $(temp.topic)\tmessage:$(String(temp.payload))")
            publish(c2, "julia", "From client 2"; qos = 2)
        elseif temp.topic == "julia"
            println("\ttopic: $(temp.topic)\tmessage:$(String(temp.payload))")
        else
            println("Wrong topic :(")
        end
    end
    return 0
end

# Messages will be put as a Message struct
# the channel Mosquitto.messages_channel.
for i = 1:200
    loop(client1; timeout = 100)
    loop(client2; timeout = 100)
    loop(client3; timeout = 100)

    subonconnect(client1, client2, client3)
    onmessage(client1, client2)
end


# Close everything
disconnect(client1)
disconnect(client2)
disconnect(client3)
lib_cleanup()