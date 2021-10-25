mutable struct Client
    id::String
    cobj::CMosquittoClient
    connected::Bool
end

function Client(ip::String, port::Int=1883; keepalive::Int = 60, id::String = randstring(15) )
    cobj = CMosquittoClient(id, clean_start = true)
    flag = connect(cobj, ip; port = port, keepalive = keepalive)
    flag != 0 && throw("connection to the broker failed" )
    flag = loop_start(cobj)
    flag != 0 && throw("could not start network loop" )
    return Client(id, cobj, true )
end

function disconnect(client::Client)
    flag = disconnect(client.cref)
    client.connected = (client.connected && !(flag == 0))
    loop_stop(client.cobj)
    return client
end

function publish(client::Client, topic::String, payload; qos::Int = 1, retain::Bool = true)
    return publish(client.cobj, topic, payload; qos = qos, retain = retain)
end

function subscribe!(client::Client, topic::String, channel::AbstractChannel; qos::Int = 1)
    subscribe(client.cobj, topic; qos = qos)
    @noinline message_callback_set(client.cobj, callbackfunc)
    return channel
end

function callbackfunc(mos::Ref{cmosquitto}, obj::Ref{Cvoid}, message::Ref{CMosquittoMessage})
    #jmessage = unsafe_load(message[].payload, message[].payloadlen)
    #push!(channel, jmessage)
    println("message received")
    return nothing
end

function unsubscribe(client::Client, topic::String)
    return unsubscribe(client.cobj, topic)
end

function startloop(client::Client)
    return loop_start(client.cobj)
end

function stoploop(client::Client)
    return loop_stop(client.cobj)
end