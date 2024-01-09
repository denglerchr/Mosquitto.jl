import Base.n_avail, Base.show

# struct Cobj with fields
# * mosc::Ptr{Cmosquitto}

# Container storing required pointers of the client.
mutable struct Cptrs
    mosc::Ptr{Cmosquitto}
    callbackobjs::Base.RefValue{CallbackObjs}

    function Cptrs(mosc::Ptr{Cmosquitto}, cbobjs)
        cobjs = new(mosc, cbobjs)
        finalizer( x->MosquittoCwrapper.destroy(x.mosc) , cobjs)
        return cobjs
    end
end

abstract type AbstractClient end

# Client, constructor below
struct Client<:AbstractClient
    id::String
    conn_status::Base.RefValue{Bool}
    cptr::Cptrs
end


function show(io::IO, client::AbstractClient)
    println(io, "MQTTClient_$(client.id)")
end


"""
    Client(ip::String, port::Int=1883; kw...)
    Client(; kw...)

Create a client connection to an MQTT broker. The id should be unique per connection. If ip and port are specified, the
client will try to immediately connect to the broker. Use the version without ip and port if you need to connect with user/password,
set a will or similar. In that case, you will have to call the `connect(client)` function manually.
Available keyword arguments:
* `id`::String : the id of the client
* `clean_session``::Bool : set to true to instruct the broker to clean all messages and subscriptions on disconnect, false to instruct it to keep them.
* `messages_channel`::Channel{MessageCB} : a channel that is receiving incoming messages
* `autocleanse_message_channel`::Bool : default true. If true, automatically remove old messages if the `messages_channel` is full
* `connect_channel`::Channel{ConnectionCB} : a channel that is receiving incoming connect/disconnect events
* `autocleanse_connect_channel`::Bool : default true. If true, automatically remove old messages if the `connect_channel` is full
* `pub_channel`::Channel{Cint} : a channel that is receiving message ids for successfully published messages
"""
function Client(ip::String, port::Int=1883; kw...)
    
    # Create a Client object
    client = Client( ; kw...)

    # Try connecting to the broker
    flag = connect(client, ip, port)
    flag != MosquittoCwrapper.MOSQ_ERR_SUCCESS && @warn("Connection to the broker failed, error $flag")

    return client
end

function Client(; id::String = randstring(15),
        clean_session::Bool = true,
        messages_channel::Channel{MessageCB} = Channel{MessageCB}(20),
        autocleanse_message_channel::Bool = true,
        connect_channel::Channel{ConnectionCB} = Channel{ConnectionCB}(5),
        autocleanse_connect_channel::Bool = true,
        pub_channel::Channel{Cint} = Channel{Cint}(5))

    # Create mosquitto object and save
    cbobjs = CallbackObjs(messages_channel, connect_channel, pub_channel, (autocleanse_message_channel, autocleanse_connect_channel))
    cbobjs_ref = Ref(cbobjs)#pointer_from_objref(channel)
    cmosc = MosquittoCwrapper.mosquitto_new(id, clean_session, cbobjs_ref)

    # Set callbacks
    cfunc_message = @cfunction(callback_message, Cvoid, (Ptr{Cmosquitto}, Ptr{CallbackObjs}, Ptr{CmosquittoMessage}))
    cfunc_publish = @cfunction(callback_publish, Cvoid, (Ptr{Cmosquitto}, Ptr{CallbackObjs}, Cint))
    cfunc_connect = @cfunction(callback_connect, Cvoid, (Ptr{Cmosquitto}, Ptr{CallbackObjs}, Cint))
    cfunc_disconnect = @cfunction(callback_disconnect, Cvoid, (Ptr{Cmosquitto}, Ptr{CallbackObjs}, Cint))

    MosquittoCwrapper.message_callback_set(cmosc, cfunc_message)
    MosquittoCwrapper.publish_callback_set(cmosc, cfunc_publish)
    MosquittoCwrapper.connect_callback_set(cmosc, cfunc_connect)
    MosquittoCwrapper.disconnect_callback_set(cmosc, cfunc_disconnect)

    # Create object
    return Client(id, Ref(false), Cptrs(cmosc, cbobjs_ref) )
end

"""
    get_messages_channel(client::AbstractClient)

Returns the channel that contains received messages for the client
"""
get_messages_channel(client::AbstractClient) = client.cptr.callbackobjs.x.messages_channel

"""
    <get_connect_channel(client::AbstractClient)

Returns the channel that contains messages on connect or diconnect events for the client
"""
get_connect_channel(client::AbstractClient) = client.cptr.callbackobjs.x.connect_channel

# Returns the channel that contains message ids of successfully publishes messages
# according to the qos chosen.
get_pub_channel(client::AbstractClient) = client.cptr.callbackobjs.x.pub_channel