mutable struct Client
    id::String
    cmosc::Ref{Cmosquitto}
    cobj::Ref{Cvoid} # do I need this? Free this?
    connected::Bool
end

function finalizer(client::Client)
    disconnect(client)
    destroy(client.cmosc)
end

function Client(ip::String, port::Int=1883; keepalive::Int = 60, id::String = randstring(15) )
    cobj = Ref{Cvoid}()
    cmosc = mosquitto_new(id, true, cobj)
    flag = connect(cmosc, ip; port = port, keepalive = keepalive)
    flag != 0 && throw("connection to the broker failed" )
    flag = loop_start(cmosc)
    flag != 0 && throw("could not start network loop" )
    return Client(id, cmosc, cobj, true )
end

function disconnect(client::Client)
    flag = disconnect(client.cmosc)
    client.connected = (client.connected && !(flag == 0))
    loop_stop(client.cmosc)
    return client
end

function publish(client::Client, topic::String, payload; qos::Int = 1, retain::Bool = true)
    return publish(client.cmosc, topic, payload; qos = qos, retain = retain)
end

function subscribe!(client::Client, topic::String; qos::Int = 1)
    subscribe(client.cmosc, topic; qos = qos)
    # Todo return channel here
    cfunc = @cfunction($callbackfunc, Cvoid, (Ptr{Cmosquitto}, Ptr{Cvoid}, Ptr{CMosquittoMessage}))
    return message_callback_set(client.cmosc, cfunc)
    # return channel
end

function callbackfunc(mos::Ref{Cmosquitto}, obj::Ref{Cvoid}, message::Ref{CMosquittoMessage})
    #jmessage = unsafe_load(message[].payload, message[].payloadlen)
    #push!(channel, jmessage)
    println("message received")
    return nothing
end

function unsubscribe(client::Client, topic::String)
    return unsubscribe(client.cmosc, topic)
end

function startloop(client::Client)
    return loop_start(client.cmosc)
end

function stoploop(client::Client)
    return loop_stop(client.cmosc)
end