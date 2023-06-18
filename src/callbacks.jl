"""
struct MessageCB with fields
* topic:: String
* payload::Vector{UInt8}

A struct containing incoming message information and payload.
"""
struct MessageCB
    topic::String
    payload::Vector{UInt8}
end

"""
struct ConnectionCB with fields
* clientptr::Ptr
* val::UInt8
* returncode::mosq_err_t

The clientptr contains the ptr of the client that connected or disconnected.
This allows to distinguish between clients.
val is 0 on disconnect and 1 on connect.
returncode is the MQTT return code which can be used to identify, e.g., the reason for a disconnect.
"""
struct ConnectionCB
    clientptr::Ptr{Cmosquitto}
    val::UInt8
    returncode::mqtt311_connack_codes
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
function callback_message(mos::Ptr{Cmosquitto}, obj::Ptr{Cvoid}, message::Ptr{CMosquittoMessage}) #, clientid::String)
    # get topic and payload from the message
    jlmessage = unsafe_load(message)
    jlpayload = [unsafe_load(jlmessage.payload, i) for i = 1:jlmessage.payloadlen]
    topic = unsafe_string(jlmessage.topic)

    # put it in the channel for further use
    if Base.n_avail(messages_channel)>=messages_channel.sz_max
        popfirst!(messages_channel)
    end
    put!(messages_channel, MessageCB(topic, jlpayload))
    
    return nothing
end


function callback_connect(mos::Ptr{Cmosquitto}, obj::Ptr{Cvoid}, rc::Cint)
    if Base.n_avail(connect_channel)>=connect_channel.sz_max
        popfirst!(connect_channel)
    end
    put!( connect_channel, ConnectionCB(mos, one(UInt8), mqtt311_connack_codes(rc) ) )
    return nothing
end


function callback_disconnect(mos::Ptr{Cmosquitto}, obj::Ptr{Cvoid}, rc::Cint)
    if Base.n_avail(connect_channel)>=connect_channel.sz_max
        popfirst!(connect_channel)
    end
    put!( connect_channel, ConnectionCB(mos, zero(UInt8), mqtt311_connack_codes(rc) ) )
    return nothing
end