mutable struct Cptrs_v5
    mosc::Ptr{Cmosquitto}
    callbackobjs::Base.RefValue{CallbackObjs_v5}

    function Cptrs_v5(mosc::Ptr{Cmosquitto}, cbobjs)
        cobjs = new(mosc, cbobjs)
        finalizer( x->MosquittoCwrapper.destroy(x.mosc) , cobjs)
        return cobjs
    end
end


struct Client_v5<:AbstractClient
    id::String
    conn_status::Base.RefValue{Bool}
    cptr::Cptrs_v5
end

"""
    Client_v5(ip::String, port::Int=1883; kw...)
    Client_v5(; kw...)

Create a client connection to an MQTT broker using the protocol version 5. The id should be unique per connection. If ip and port are specified, the
client will try to immediately connect to the broker. Use the version without ip and port if you need to connect with user/password,
set a will or similar. In that case, you will have to call the `connect(client)` function manually.
Available keyword arguments:
* `id`::String : the id of the client
* `messages_channel`::Channel{MessageCB} : a channel that is receiving incoming messages
* `autocleanse_message_channel`::Bool : default true. If true, automatically remove old messages if the `messages_channel` is full
* `connect_channel`::Channel{ConnectionCB} : a channel that is receiving incoming connect/disconnect events
* `autocleanse_connect_channel`::Bool : default true. If true, automatically remove old messages if the `connect_channel` is full
* `pub_channel`::Channel{Cint} : a channel that is receiving message ids for successfully published messages
"""
function Client_v5(ip::String, port::Int=1883; kw...)
    
    # Create a Client object
    client = Client_v5( ; kw...)

    # Try connecting to the broker
    flag = connect(client, ip, port)
    flag != MosquittoCwrapper.MOSQ_ERR_SUCCESS && @warn("Connection to the broker failed, error $flag")

    return client
end

function Client_v5(; id::String = randstring(15), 
                    messages_channel::Channel{MessageCB_v5} = Channel{MessageCB_v5}(20),
                    autocleanse_message_channel::Bool = true,
                    connect_channel::Channel{ConnectionCB_v5} = Channel{ConnectionCB_v5}(5),
                    autocleanse_connect_channel::Bool = true,
                    pub_channel::Channel{Tuple{Cint, Cint}} = Channel{Tuple{Cint, Cint}}(5))

    # Create mosquitto object and save
    cbobjs = CallbackObjs_v5(messages_channel, connect_channel, pub_channel, (autocleanse_message_channel, autocleanse_connect_channel))
    cbobjs_ref = Ref(cbobjs)#pointer_from_objref(channel)
    cmosc = MosquittoCwrapper.mosquitto_new(id, true, cbobjs_ref)

    # Set to use V5
    msg = MosquittoCwrapper.int_option(cmosc, MosquittoCwrapper.MOSQ_OPT_PROTOCOL_VERSION , MosquittoCwrapper.MQTT_PROTOCOL_V5)
    @assert(msg == MosquittoCwrapper.MOSQ_ERR_SUCCESS, "Could not set client to use MQTTv5. Return value $msg")

    # Set callbacks
    cfunc_message = @cfunction(callback_message_v5, Cvoid, (Ptr{Cmosquitto}, Ptr{CallbackObjs_v5}, Ptr{CmosquittoMessage}, Ptr{CmosquittoProperty}))
    cfunc_publish = @cfunction(callback_publish_v5, Cvoid, (Ptr{Cmosquitto}, Ptr{CallbackObjs_v5}, Cint, Cint, Ptr{CmosquittoProperty}))
    cfunc_connect = @cfunction(callback_connect_v5, Cvoid, (Ptr{Cmosquitto}, Ptr{CallbackObjs_v5}, Cint, Cint, Ptr{CmosquittoProperty}))
    cfunc_disconnect = @cfunction(callback_disconnect_v5, Cvoid, (Ptr{Cmosquitto}, Ptr{CallbackObjs_v5}, Cint, Ptr{CmosquittoProperty}))

    MosquittoCwrapper.message_v5_callback_set(cmosc, cfunc_message)
    MosquittoCwrapper.publish_v5_callback_set(cmosc, cfunc_publish)
    MosquittoCwrapper.connect_v5_callback_set(cmosc, cfunc_connect)
    MosquittoCwrapper.disconnect_v5_callback_set(cmosc, cfunc_disconnect)

    # Create object
    return Client_v5(id, Ref(false), Cptrs_v5(cmosc, cbobjs_ref) )
end