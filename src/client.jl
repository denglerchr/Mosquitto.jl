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
        finalizer( x->(disconnect(x.mosc); destroy(x.mosc)) , cobjs)
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
    flag != MOSQ_ERR_SUCCESS && @warn("Connection to the broker failed, error $flag")

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
    cmosc = mosquitto_new(id, true, cbobjs_ref)

    # Set callbacks
    cfunc_message = @cfunction(callback_message, Cvoid, (Ptr{Cmosquitto}, Ptr{CallbackObjs}, Ptr{CMosquittoMessage}))
    cfunc_publish = @cfunction(callback_publish, Cvoid, (Ptr{Cmosquitto}, Ptr{CallbackObjs}, Cint))
    cfunc_connect = @cfunction(callback_connect, Cvoid, (Ptr{Cmosquitto}, Ptr{CallbackObjs}, Cint))
    cfunc_disconnect = @cfunction(callback_disconnect, Cvoid, (Ptr{Cmosquitto}, Ptr{CallbackObjs}, Cint))

    message_callback_set(cmosc, cfunc_message)
    publish_callback_set(cmosc, cfunc_publish)
    connect_callback_set(cmosc, cfunc_connect)
    disconnect_callback_set(cmosc, cfunc_disconnect)

    # Create object
    return Client(id, Ref(false), cbobjs, Cptrs(cmosc) )
end

get_messages_channel(client::Client) = client.cbobjs.messages_channel
get_connect_channel(client::Client) = client.cbobjs.connect_channel


"""
    connect(client::Client, ip::String, port::Int; kwargs...)

Connect the client to a broker. kwargs are:
* username::String = ""      A username, should one be required
* password::String = ""      A password belonging to the username
* keepalive::Int = 60   Maximal of time the client has to send PINGREQ or a message before disconnection
"""
function connect(client::Client, ip::String, port::Int; username::String = "", password::String = "", keepalive::Int = 60)
    if username != ""
        flag = username_pw_set(client.cptr.mosc, username, password)
        flag != MOSQ_ERR_SUCCESS && @warn("Couldnt set password and username, error $flag")
    end
    flag = connect(client.cptr.mosc, ip; port = port, keepalive = keepalive)
    flag == MOSQ_ERR_SUCCESS ? (client.conn_status.x = true) : @warn("Connection to broker failed, error $flag")
    return flag
end


"""
    disconnect(client::Client)

Disconnect the client.
"""
function disconnect(client::Client)
    flag = disconnect(client.cptr.mosc)
    flag == MOSQ_ERR_SUCCESS && (client.conn_status.x = false)
    return flag
end


"""
    reconnect(client::Client)
"""
function reconnect(client::Client)
    flag = reconnect(client.cptr.mosc)
    flag == MOSQ_ERR_SUCCESS && (client.conn_status.x = true)
    return flag
end


"""
    publish(client::Client, topic::String, payload; kw...)

Publish a message to the broker. Keyword arguments
* qos::Int = 1 : Quality of service
* retain::Bool = false : if true, the broker will store this message
* waitcb = false : if true, wait until the message was received by the broker to return. If set to true, the network loop must run asynchronously, else the function might just block forever.
"""
function publish(client::Client, topic::String, payload; qos::Int = 1, retain::Bool = false, waitcb::Bool = false) 
    mid = Ref(zero(Cint)) # message id
    rv = publish(client.cptr.mosc, mid, topic, payload; qos = qos, retain = retain)

    # possibly wait for message to be sent successfully to broker
    if waitcb && (rv == MOSQ_ERR_SUCCESS)
        mid2 = mid.x - Cint(1)
        while mid.x != mid2
            mid2 = take!(client.cbobjs.pub_channel)
        end
    end
    return rv
end


"""
    subscribe(client::Client, topic::String; qos::Int = 1)

Subscribe to a topic. Received messages will be accessible Mosquitto.messages_channel as a Tuple{String, Vector{Uint8}}.
"""
subscribe(client::Client, topic::String; qos::Int = 1) = subscribe(client.cptr.mosc, topic; qos = qos)


"""
    unsubscribe(client::Client, topic::String)

Unsubscribe from a topic.
"""
unsubscribe(client::Client, topic::String) = unsubscribe(client.cptr.mosc, topic)


"""
    loop(client::Client; timeout::Int = 1000, ntimes::Int = 1)

Perform a network loop. This will get messages of subscriptions and send published messages.
"""
function loop(client::Client; timeout::Int = 1000, ntimes::Int = 1, autoreconnect::Bool = true) 
    out = MOSQ_ERR_INVAL
    for _ = 1:ntimes
        out = loop(client.cptr.mosc; timeout = timeout)
        if autoreconnect && out == MOSQ_ERR_CONN_LOST
            flag = reconnect(client)
            client.conn_status.x = ifelse( flag == MOSQ_ERR_SUCCESS, true, false )  
        end
    end
    return out
end


"""
    loop_forever(client::Ref{Cmosquitto}; timeout::Int = 1000)

Continuously perform network loop. Reconnecting is handled, and the function returns after 
disconnect(client) is called. Calls the mosquitto C library using @threadcall to allow
asynchronous execution.
This function segfaults on older Julia versions, a Mosquitto.loop_forever2(client) functions can
be used for a worse performance, but more stable version of it.
"""
function loop_forever(client::Client; timeout::Int = 1000)
    return loop_forever(client.cptr.mosc; timeout = timeout, max_packets = 1)
end


"""
loop_forever2(client::Ref{Cmosquitto}; timeout::Int = 10)

Continuously perform network loop. Reconnecting is handled, and the function returns after 
disconnect(client) is called. This is a slower version of loop_forever, however it works on older Julia versions.
"""
function loop_forever2(client::Client; timeout::Int = 10)
    rc = MOSQ_ERR_SUCCESS
    while rc != MOSQ_ERR_NO_CONN
        rc = loop(client; timeout = timeout)
        yield()
    end
    return MOSQ_ERR_SUCCESS
end


"""
    tls_set(client::Client, cafile::String; certfile::String = "", keyfile::String = "")
"""
function tls_set(client::Client, cafile::String; certfile::String = "", keyfile::String = "")
    xor( certfile == "", keyfile == "" ) && throw("You need to either provide both cert and key files, or none of both")
    if certfile == ""
        return tls_set(client.cptr.mosc, cafile, C_NULL, C_NULL, C_NULL, C_NULL)
    else
        return tls_set(client.cptr.mosc, cafile, C_NULL, certfile, keyfile, C_NULL)
    end
end


"""
    tls_plk_set(client::Client, psk::String, identity::String, ciphers::Union{Nothing, String})
"""
function tls_psk_set(client::Client, psk::String, identity::String, ciphers::Union{Nothing, String} = nothing)
    return tls_psk_set(client.cptr.mosc, psk, identity, ciphers)    
end