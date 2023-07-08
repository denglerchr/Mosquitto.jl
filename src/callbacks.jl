"""
struct MessageCB with fields
* clientid::String -> the id of the client that received the message
* topic:: String -> the topic where the message was received from
* payload::Vector{UInt8} -> the message content

A struct containing incoming message information and payload.
"""
struct MessageCB
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
    val::UInt8
    returncode::mosq_err_t
end


"""
struct CallbackObjs with fields
* messages_channel::AbstractChannel{MessageCB}
* connect_channel::AbstractChannel{ConnectionCB}
* pub_channel::AbstractChannel{Cint}
* autocleanse::Tuple{Bool, Bool}

Contains Julia objects used in the Mosquitto callback functions. Passed to the
callback functions as a pointer.
"""
struct CallbackObjs
    messages_channel::AbstractChannel{MessageCB}
    connect_channel::AbstractChannel{ConnectionCB}
    pub_channel::AbstractChannel{Cint}
    autocleanse::Tuple{Bool, Bool}
end


# This callback function puts any message on arrival in the channel
# messages_channel which is a Channel{Mosquitto.Message}(20)
# The CMosquittoMessage does not have to be free-ed, it is free-ed by Mosquitto
# according to https://github.com/eclipse/mosquitto/issues/549
function callback_message(mos::Ptr{Cmosquitto}, obj::Ptr{CallbackObjs}, message::Ptr{CMosquittoMessage}) #, clientid::String)
    # get topic and payload from the message
    jlmessage = unsafe_load(message)
    jlpayload = [unsafe_load(jlmessage.payload, i) for i = 1:jlmessage.payloadlen]
    topic = unsafe_string(jlmessage.topic)
    cbobjs = unsafe_load(obj)

    # put it in the channel for further use
    if cbobjs.autocleanse[1] && Base.n_avail(cbobjs.messages_channel)>=cbobjs.messages_channel.sz_max
        popfirst!(cbobjs.messages_channel)
    end
    put!(cbobjs.messages_channel, MessageCB( topic, jlpayload))
    return nothing
end


function callback_publish(mos::Ptr{Cmosquitto}, obj::Ptr{CallbackObjs}, mid::Cint)
    cbobjs = unsafe_load(obj)
    if Base.n_avail(cbobjs.pub_channel)>=cbobjs.pub_channel.sz_max
        popfirst!(cbobjs.pub_channel)
    end
    put!( cbobjs.pub_channel, mid )
    return nothing
end


function callback_connect(mos::Ptr{Cmosquitto}, obj::Ptr{CallbackObjs}, rc::Cint)
    cbobjs = unsafe_load(obj)
    if cbobjs.autocleanse[2] && Base.n_avail(cbobjs.connect_channel)>=cbobjs.connect_channel.sz_max
        popfirst!(cbobjs.connect_channel)
    end
    put!( cbobjs.connect_channel, ConnectionCB( one(UInt8), mosq_err_t(rc) ) )
    return nothing
end


function callback_disconnect(mos::Ptr{Cmosquitto}, obj::Ptr{CallbackObjs}, rc::Cint)
    cbobjs = unsafe_load(obj)
    if cbobjs.autocleanse[2] && Base.n_avail(cbobjs.connect_channel)>=cbobjs.connect_channel.sz_max
        popfirst!(cbobjs.connect_channel)
    end
    put!( cbobjs.connect_channel, ConnectionCB( zero(UInt8), mosq_err_t(rc) ) )
    return nothing
end