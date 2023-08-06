import Base.n_avail, Base.show

"""
struct Cobj with fields
* mosc::Ptr{Cmosquitto}

Container storing required pointers of the client.
"""
mutable struct Cptrs
    mosc::Ptr{Cmosquitto}

    function Cptrs(mosc::Ptr{Cmosquitto})
        cobjs = new(mosc)
        finalizer( x->(MosquittoCwrapper.disconnect(x.mosc); MosquittoCwrapper.destroy(x.mosc)) , cobjs)
        return cobjs
    end
end


# Client, constructor below
struct Client
    id::String
    conn_status::Base.RefValue{Bool}
    cbobjs::CallbackObjs
    cptr::Cptrs
end


function show(io::IO, client::Client)
    println("MQTTClient_$(client.id)")
end


"""
    Client(ip::String, port::Int=1883; kw...)
    Client(; kw...)

Create a client connection to an MQTT broker. The id should be unique per connection. If ip and port are specified, the
client will immediately connect to the broker. Use the version without ip and port if you need to connect with user/password.
You will have to call the connect(client) function manually.
Available keyword arguments:
* `id`::String : the id of the client
* `messages_channel`::Channel{MessageCB} : a channel that is receiving incoming messages
* `autocleanse_message_channel`::Bool : default false, if true, automatically remove old messages if the `messages_channel` is full
* `connect_channel`::Channel{ConnectionCB} : a channel that is receiving incoming connect/disconnect events
* `autocleanse_connect_channel`::Bool : default false, if true, automatically remove old messages if the `connect_channel` is full
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
                    messages_channel::Channel{MessageCB} = Channel{MessageCB}(20),
                    autocleanse_message_channel::Bool = false,
                    connect_channel::Channel{ConnectionCB} = Channel{ConnectionCB}(5),
                    autocleanse_connect_channel::Bool = false,
                    pub_channel::Channel{Cint} = Channel{Cint}(5))

    # Create mosquitto object and save
    cbobjs = CallbackObjs(messages_channel, connect_channel, pub_channel, (autocleanse_message_channel, autocleanse_connect_channel))
    cbobjs_ref = Ref(cbobjs)#pointer_from_objref(channel)
    cmosc = MosquittoCwrapper.mosquitto_new(id, true, cbobjs_ref)

    # Set callbacks
    cfunc_message = @cfunction(callback_message, Cvoid, (Ptr{Cmosquitto}, Ptr{CallbackObjs}, Ptr{CMosquittoMessage}))
    cfunc_publish = @cfunction(callback_publish, Cvoid, (Ptr{Cmosquitto}, Ptr{CallbackObjs}, Cint))
    cfunc_connect = @cfunction(callback_connect, Cvoid, (Ptr{Cmosquitto}, Ptr{CallbackObjs}, Cint))
    cfunc_disconnect = @cfunction(callback_disconnect, Cvoid, (Ptr{Cmosquitto}, Ptr{CallbackObjs}, Cint))

    MosquittoCwrapper.message_callback_set(cmosc, cfunc_message)
    MosquittoCwrapper.publish_callback_set(cmosc, cfunc_publish)
    MosquittoCwrapper.connect_callback_set(cmosc, cfunc_connect)
    MosquittoCwrapper.disconnect_callback_set(cmosc, cfunc_disconnect)

    # Create object
    return Client(id, Ref(false), cbobjs, Cptrs(cmosc) )
end

get_messages_channel(client::Client) = client.cbobjs.messages_channel
get_connect_channel(client::Client) = client.cbobjs.connect_channel