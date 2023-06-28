"""
struct MessageCB with fields
* clientid::String -> the id of the client that received the message
* topic:: String -> the topic where the message was received from
* payload::Vector{UInt8} -> the message content

A struct containing incoming message information and payload.
"""
struct MessageCB
    clientid::String
    topic::String
    payload::Vector{UInt8}
end

"""
struct ConnectionCB with fields
* clientid::String -> the id of the client that had a connection event
* val::UInt8 -> 0 on disconnect and 1 on connect.
* returncode::mosq_err_t -> the MQTT return code, possible value in mosq_err_t
"""
struct ConnectionCB
    clientid::String
    val::UInt8
    returncode::mosq_err_t
end


const messages_channel = Channel{MessageCB}(20)
const connect_channel = Channel{ConnectionCB}(5)

"""
    get_messages_channel()

Returns the channel to which received messages are sent. The channel is a Channel{MessageCB}(20).
See ?Mosquitto.MessageCB for information on the struct
"""
get_messages_channel() = messages_channel

"""
    get_connect_channel()

Returns the channel to which event notifications for connections or disconnections are sent. The channel is a Channel{ConnectionCB}(5).
See ?Mosquitto.ConnectionCB for information on the struct
"""
get_connect_channel() = connect_channel


# This callback function puts any message on arrival in the channel
# messages_channel which is a Channel{Mosquitto.Message}(20)
# The CMosquittoMessage does not have to be free-ed, it is free-ed by Mosquitto
# according to https://github.com/eclipse/mosquitto/issues/549
function callback_message(mos::Ptr{Cmosquitto}, obj::Ptr{UInt8}, message::Ptr{CMosquittoMessage}) #, clientid::String)
    # get topic and payload from the message
    jlmessage = unsafe_load(message)
    jlpayload = [unsafe_load(jlmessage.payload, i) for i = 1:jlmessage.payloadlen]
    topic = unsafe_string(jlmessage.topic)
    clientid = unsafe_string(obj)

    # put it in the channel for further use
    if Base.n_avail(messages_channel)>=messages_channel.sz_max
        popfirst!(messages_channel)
    end
    put!(messages_channel, MessageCB(clientid, topic, jlpayload))
    return nothing
end


function callback_connect(mos::Ptr{Cmosquitto}, obj::Ptr{UInt8}, rc::Cint)
    if Base.n_avail(connect_channel)>=connect_channel.sz_max
        popfirst!(connect_channel)
    end
    clientid = unsafe_string(obj)
    put!( connect_channel, ConnectionCB(clientid, one(UInt8), mosq_err_t(rc) ) )
    return nothing
end


function callback_disconnect(mos::Ptr{Cmosquitto}, obj::Ptr{UInt8}, rc::Cint)
    if Base.n_avail(connect_channel)>=connect_channel.sz_max
        popfirst!(connect_channel)
    end
    clientid = unsafe_string(obj)
    put!( connect_channel, ConnectionCB(clientid, zero(UInt8), mosq_err_t(rc) ) )
    return nothing
end