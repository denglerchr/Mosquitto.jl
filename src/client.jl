import Base.n_avail, Base.show

"""
struct Cobj with fields
* mosc::Ptr{Cmosquitto}
* obj::Ptr{UInt8}

Container storing required pointers of the client.
"""
mutable struct Cobjs
    mosc::Ptr{Cmosquitto}
    obj::Ptr{UInt8}

    function Cobjs(mosc::Ptr{Cmosquitto}, obj::Ptr{UInt8})
        cobjs = new(mosc, obj)
        finalizer( x->destroy(x.mosc) , cobjs)
        return cobjs
    end
end


"""
struct MoscStatus with fields
* conn_status::Bool

Container storing status flags
"""
mutable struct MoscStatus
    conn_status::Bool
end

# Client, constructor below
struct Client
    id::String
    cptr::Cobjs
    status::MoscStatus
end


function show(io::IO, client::Client)
    println("MQTTClient_$(client.id)")
end


"""
    Client(ip::String, port::Int=1883; id::String = randstring(15))
    Client(; id::String = randstring(15))

Create a client connection to an MQTT broker. The id should be unique per connection. If ip and port are specified, the
client will immediately connect to the broker. Use the version without ip and port if you need to connect with user/password.
You will have to call the connect(client) function manually.
"""
function Client(ip::String, port::Int=1883; id::String = randstring(15))
    # Create a Client object
    client = Client( ; id = id )

    # Try connecting to the broker
    flag = connect(client, ip, port)
    flag != MOSQ_ERR_SUCCESS && @warn("Connection to the broker failed, error $flag")

    return client
end

function Client(; id::String = randstring(15))
    # Create mosquitto object and save
    # id in obj to have it available in callback
    id_ptr = pointer(id)
    cmosc = mosquitto_new(id, true, id_ptr)

    # Set callbacks
    cfunc_message = @cfunction(callback_message, Cvoid, (Ptr{Cmosquitto}, Ptr{UInt8}, Ptr{CMosquittoMessage}))
    cfunc_connect = @cfunction(callback_connect, Cvoid, (Ptr{Cmosquitto}, Ptr{UInt8}, Cint))
    cfunc_disconnect = @cfunction(callback_disconnect, Cvoid, (Ptr{Cmosquitto}, Ptr{UInt8}, Cint))

    message_callback_set(cmosc, cfunc_message)
    connect_callback_set(cmosc, cfunc_connect)
    disconnect_callback_set(cmosc, cfunc_disconnect)

    # Create object
    return Client(id, Cobjs(cmosc, id_ptr), MoscStatus(false) )
end


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
    flag == MOSQ_ERR_SUCCESS ? (client.status.conn_status = true) : @warn("Connection to broker failed, error $flag")
    return flag
end


"""
    disconnect(client::Client)

Disconnect the client.
"""
function disconnect(client::Client)
    flag = disconnect(client.cptr.mosc)
    flag == MOSQ_ERR_SUCCESS && (client.status.conn_status = false)
    return flag
end


"""
    reconnect(client::Client)
"""
function reconnect(client::Client)
    flag = reconnect(client.cptr.mosc)
    flag == MOSQ_ERR_SUCCESS && (client.status.conn_status = true)
    return flag
end


"""
    publish(client::Client, topic::String, payload; qos::Int = 1, retain::Bool = false)

Publish a message to the broker. 
"""
publish(client::Client, topic::String, payload; qos::Int = 1, retain::Bool = false) = publish(client.cptr.mosc, topic, payload; qos = qos, retain = retain)


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
            client.status.conn_status = ifelse( flag == MOSQ_ERR_SUCCESS, true, false )  
        end
    end
    return out
end


"""
    loop_forever(client::Ref{Cmosquitto}; timeout::Int = 1000)

Blocking, continuously perform network loop. Run in another thread to allow handling messages. Reconnecting is handled, and the function returns after 
disconnect(client) is called.
"""
function loop_forever(client::Client; timeout::Int = 1000)
    return loop_forever(client.cptr.mosc; timeout = timeout, max_packets = 1)
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