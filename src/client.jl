import Base.n_avail, Base.show

"""
struct Cobj with fields
* mosc::Ref{Cmosquitto}
* obj::Ref{Cvoid}
* conncb::Ref{Cvoid}
* dconncb::Ref{Cvoid}

Container storing required pointers of the client.
"""
struct Cobjs
    mosc::Ref{Cmosquitto}
    obj::Ref{Cvoid}
    conncb::Ref{Cvoid}
    dconncb::Ref{Cvoid}
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


# Clean up memory when garbage collected
function finalizer(client::Client)
    disconnect(client)
    destroy(client.cptr.mosc)
end


"""
    Client(ip::String, port::Int=1883; kwargs...)

Create a client connection to an MQTT broker. Possible key word arguments are:
* id::String = randstring(15)  The id should be unique per connection.
* connectme::Bool = true  Connect immediately if true. If false, you need to manually use *connect(client, ip, port)* and input arguments are not used.
* startloop::Bool = true  If true, and Threads.nthreads()>1, the network loop will be executed regularly after connection.

    Client( ; id::String = randstring(15))

Create a client structure without connecting to a broker or starting a network loop. 
"""
function Client(ip::String, port::Int=1883; id::String = randstring(15), connectme::Bool = true, startloop::Bool = true)
    # Create a Client object
    client = Client( ; id = id )

    # Possibly Connect to broker
    if connectme
        flag = connect(client, ip, port)
        flag != 0 && @warn("Connection to the broker failed")
    end

    return client
end

function Client(; id::String = randstring(15))
    # Create mosquitto object
    cobj = Ref{Cvoid}()
    cmosc = mosquitto_new(id, true, cobj)

    # Set callbacks
    #f_message_cb(mos, obj, message) = callback_message(mos, obj, message, id)
    cfunc_message = @cfunction(callback_message, Cvoid, (Ptr{Cmosquitto}, Ptr{Cvoid}, Ptr{CMosquittoMessage}))
    message_callback_set(cmosc, cfunc_message)

    cfunc_connect = @cfunction(callback_connect, Cvoid, (Ptr{Cmosquitto}, Ptr{Cvoid}, Cint))
    connect_callback_set(cmosc, cfunc_connect)

    cfunc_disconnect = @cfunction(callback_disconnect, Cvoid, (Ptr{Cmosquitto}, Ptr{Cvoid}, Cint))
    disconnect_callback_set(cmosc, cfunc_disconnect)

    # Create object
    return Client(id, Cobjs(cmosc, cobj, cfunc_connect, cfunc_disconnect), MoscStatus(false) )
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
        flag != 0 && @warn("Couldnt set password and username, error $flag")
    end
    flag = connect(client.cptr.mosc, ip; port = port, keepalive = keepalive)
    flag == 0 ? (client.status.conn_status = true) : @warn("Connection to broker failed")
    return flag
end


"""
    disconnect(client::Client)
"""
function disconnect(client::Client)
    flag = disconnect(client.cptr.mosc)
    flag == 0 && (client.status.conn_status = false)
    return flag
end


"""
    reconnect(client::Client)
"""
function reconnect(client::Client)
    flag = reconnect(client.cptr.mosc)
    flag == 0 && (client.status.conn_status = true)
    return flag
end


"""
    publish(client::Client, topic::String, payload; qos::Int = 1, retain::Bool = true)

Publish a message to the broker.
"""
publish(client::Client, topic::String, payload; qos::Int = 1, retain::Bool = true) = publish(client.cptr.mosc, topic, payload; qos = qos, retain = retain)


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