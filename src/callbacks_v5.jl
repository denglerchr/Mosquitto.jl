"""
struct MessageCB with fields
* clientid::String -> the id of the client that received the message
* topic:: String -> the topic where the message was received from
* payload::Vector{UInt8} -> the message content

A struct containing incoming message information and payload.
"""
struct MessageCB_v5
    topic::String
    payload::Vector{UInt8}
    properties::Vector{Property}
end

"""
struct ConnectionCB with fields
* clientid::String -> the id of the client that had a connection event
* val::UInt8 -> 0 on disconnect and 1 on connect.
* returncode::mosq_err_t -> the MQTT return code, possible value in mosq_err_t
"""
struct ConnectionCB_v5
    val::UInt8
    returncode::MosquittoCwrapper.mosq_err_t
    properties::Vector{Property}
end

# TODO adapt all of this to include properties

# void 		(*on_message)(struct mosquitto *, void *, const struct mosquitto_message *, const mosquitto_property *props)
function callback_message_v5(mos::Ptr{Cmosquitto}, obj::Ptr{CallbackObjs}, message::Ptr{CMosquittoMessage}) #, clientid::String)
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


# void 		(*on_publish)(struct mosquitto *, void *, int, int, const mosquitto_property *props)
function callback_publish_v5(mos::Ptr{Cmosquitto}, obj::Ptr{CallbackObjs}, mid::Cint)
    cbobjs = unsafe_load(obj)
    if Base.n_avail(cbobjs.pub_channel)>=cbobjs.pub_channel.sz_max
        popfirst!(cbobjs.pub_channel)
    end
    put!( cbobjs.pub_channel, mid )
    return nothing
end


# void 		(*on_connect)(struct mosquitto *, void *, int, int, const mosquitto_property *props)
function callback_connect_v5(mos::Ptr{Cmosquitto}, obj::Ptr{CallbackObjs}, rc::Cint)
    cbobjs = unsafe_load(obj)
    if cbobjs.autocleanse[2] && Base.n_avail(cbobjs.connect_channel)>=cbobjs.connect_channel.sz_max
        popfirst!(cbobjs.connect_channel)
    end
    put!( cbobjs.connect_channel, ConnectionCB( one(UInt8), MosquittoCwrapper.mosq_err_t(rc) ) )
    return nothing
end


# void 		(*on_disconnect)(struct mosquitto *, void *, int, const mosquitto_property *props)
function callback_disconnect_v5(mos::Ptr{Cmosquitto}, obj::Ptr{CallbackObjs}, rc::Cint)
    cbobjs = unsafe_load(obj)
    if cbobjs.autocleanse[2] && Base.n_avail(cbobjs.connect_channel)>=cbobjs.connect_channel.sz_max
        popfirst!(cbobjs.connect_channel)
    end
    put!( cbobjs.connect_channel, ConnectionCB( zero(UInt8), MosquittoCwrapper.mosq_err_t(rc) ) )
    return nothing
end