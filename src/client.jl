import Base.n_avail

mutable struct Client
    id::String
    cmosc::Ref{Cmosquitto}
    cobj::Ref{Cvoid} # do I need this? Free this?
    channel::AbstractChannel
end

function finalizer(client::Client)
    disconnect(client)
    destroy(client.cmosc)
end

function Client(ip::String, port::Int=1883; keepalive::Int = 60, id::String = randstring(15), channel::AbstractChannel = Channel{Any}(5) )
    cobj = Ref{Cvoid}()
    cmosc = mosquitto_new(id, true, cobj)
    flag = connect(cmosc, ip; port = port, keepalive = keepalive)
    flag != 0 && throw("connection to the broker failed" )
    # Set callbacks
    #f_callback(mos, obj, message) = callback_message(mos, obj, message)#, channel)
    cfunc = @cfunction($callback_message, Cvoid, (Ptr{Cmosquitto}, Ptr{Cvoid}, Ptr{CMosquittoMessage}))
    message_callback_set(cmosc, cfunc)
    # Start (julia) loop here
    return Client(id, cmosc, cobj, channel)
end

function disconnect(client::Client)
    flag = disconnect(client.cmosc)
    # Stop (julia) loop here
    return client
end

function publish(client::Client, topic::String, payload; qos::Int = 1, retain::Bool = true)
    return publish(client.cmosc, topic, payload; qos = qos, retain = retain)
end

function subscribe(client::Client, topic::String; qos::Int = 1)
    return subscribe(client.cmosc, topic; qos = qos)
end

function callback_message(mos::Ref{Cmosquitto}, obj::Ref{Cvoid}, message::Ref{CMosquittoMessage})#, channel::AbstractChannel)
    jlmessage = unsafe_load(message)
    println("message received of length $(jlmessage.payloadlen).")

    jlpayload = [unsafe_load(jlmessage.payload, i) for i = 1:jlmessage.payloadlen]
    println(String(jlpayload))
    #if n_avail(channel)>=channel.sz_max
    #    take!(channel) # remove one message
    #end
    #put!(channel, jmessage)
    return nothing
end

function unsubscribe(client::Client, topic::String)
    return unsubscribe(client.cmosc, topic)
end

function loop(client::Client; timeout::Int = 2000)
    return loop(client.cmosc; timeout = timeout)
end