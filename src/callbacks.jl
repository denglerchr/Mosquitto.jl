"""
struct Message with fields
* clientid::String
* topic:: String
* payload::Vector{UInt8}

A struct containing incoming message information and payload.
"""
struct MessageCB
    #clientid::String
    topic::String
    payload::Vector{UInt8}
end

struct ConnectionCB
    clientid::String
    val::UInt8
    returncode::Cint
end

const messages_channel = Channel{MessageCB}(20)
const connect_channel = Channel{ConnectionCB}(5)

get_messages_channel() = messages_channel
get_connect_channel() = connect_channel

# This callback function puts any message on arrival in the channel
# messages_channel which is a Channel{Mosquitto.Message}(20)
function callback_message(mos::Ptr{Cmosquitto}, obj::Ptr{Cvoid}, message::Ptr{CMosquittoMessage}) #, clientid::String)
    # get topic and payload from the message
    jlmessage = unsafe_load(message)
    jlpayload = [unsafe_load(jlmessage.payload, i) for i = 1:jlmessage.payloadlen]
    topic = unsafe_string(jlmessage.topic)

    # put it in the channel for further use
    if Base.n_avail(messages_channel)>=messages_channel.sz_max
        take!(messages_channel)
    end
    put!(messages_channel, MessageCB(topic, jlpayload))
    
    return nothing
end


function callback_connect(mos::Ptr{Cmosquitto}, obj::Ptr{Cvoid}, rc::Cint, id::String)
    if Base.n_avail(connect_channel)>=connect_channel.sz_max
        take!(connect_channel)
    end
    put!( connect_channel, ConnectionCB(id, one(UInt8), rc ) )
    return nothing
end


function callback_disconnect(mos::Ptr{Cmosquitto}, obj::Ptr{Cvoid}, rc::Cint, id::String)
    if Base.n_avail(connect_channel)>=connect_channel.sz_max
        take!(connect_channel)
    end
    put!( connect_channel, ConnectionCB(id, zero(UInt8), rc ) )
    return nothing
end