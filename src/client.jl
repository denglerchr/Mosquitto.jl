import Base.n_avail, Base.show

# Would prefer to have this per client, but couldnt get it to work with cfunction
const messages_channel = Channel{Tuple{String, Vector{UInt8}}}(20)


mutable struct Client
    id::String
    cmosc::Ref{Cmosquitto}
    cobj::Ref{Cvoid}
    loop_channel::AbstractChannel{Int}
    loop_status::Bool
end


function show(io::IO, client::Client)
    println("MQTTClient_$(client.id)")
end


function finalizer(client::Client)
    disconnect(client)
    destroy(client.cmosc)
end


"""
    Client(ip::String, port::Int=1883; kwargs...)

Create a client connection to an MQTT broker. Possible key word arguments are:
* keepalive::Int = 60   Maximal of time the client has to send PINGREQ or a message before disconnection
* id::String = randstring(15)  The id should be unique per connection.
* startloop:Bool = true  If true, and Threads.nthreads()>1, the network loop will be executed regularly after connection.
"""
function Client(ip::String, port::Int=1883; keepalive::Int = 60, id::String = randstring(15), startloop::Bool = true)
    # Create mosquitto object
    cobj = Ref{Cvoid}()
    cmosc = mosquitto_new(id, true, cobj)

    # Connect to broker
    flag = connect(cmosc, ip; port = port, keepalive = keepalive)
    flag != 0 && throw("connection to the broker failed" )
    
    # Set callbacks
    #f_callback(mos, obj, message) = callback_message(mos, obj, message, channel)
    cfunc = @cfunction($callback_message, Cvoid, (Ptr{Cmosquitto}, Ptr{Cvoid}, Ptr{CMosquittoMessage}))
    message_callback_set(cmosc, cfunc)

    # Create object
    loop_channel = Channel{Int}(1)
    client = Client(id, cmosc, cobj, loop_channel, false)

    # Start loop if it can be started without blocking
    if startloop && Threads.nthreads()>1
        loop_start(client)
    elseif startloop
        println("Single thread, loop will be blocking, start it manually using loop_start(::Client) or call loop(client) regularly.")
    end

    return client
end

function disconnect(client::Client)
    loop_stop(client)
    disconnect(client.cmosc)
    return client
end

reconnect(client::Client) = reconnect(client.cmosc)

"""
    publish(client::Client, topic::String, payload; qos::Int = 1, retain::Bool = true)

Publish a message to the broker.
"""
publish(client::Client, topic::String, payload; qos::Int = 1, retain::Bool = true) = publish(client.cmosc, topic, payload; qos = qos, retain = retain)


"""
    subscribe(client::Client, topic::String; qos::Int = 1)

Subscribe to a topic. Received messages will be accessible Mosquitto.messages_channel as a Tuple{String, Vector{Uint8}}.
"""
subscribe(client::Client, topic::String; qos::Int = 1) = subscribe(client.cmosc, topic; qos = qos)


"""
    unsubscribe(client::Client, topic::String)

Unsubscribe from a topic.
"""
unsubscribe(client::Client, topic::String) = unsubscribe(client.cmosc, topic)

# This callback function puts any message on arrival in the channel
# messages_channel which is a Channel{Tuple{String, Vector{UInt8}}}(20)
function callback_message(mos::Ptr{Cmosquitto}, obj::Ptr{Cvoid}, message::Ptr{CMosquittoMessage})
    # get topic and payload from the message
    jlmessage = unsafe_load(message)
    jlpayload = [unsafe_load(jlmessage.payload, i) for i = 1:jlmessage.payloadlen]
    topic = unsafe_string(jlmessage.topic)

    # put it in the channel for further use
    if Base.n_avail(messages_channel)>=messages_channel.sz_max
        take!(messages_channel)
    end
    put!(messages_channel, (topic, jlpayload))
    
    return nothing
end