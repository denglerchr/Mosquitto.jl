import Base.n_avail, Base.show


mutable struct Client
    id::String
    cmosc::Ref{Cmosquitto}
    cobj::Ref{Cvoid}
    loop_channel::AbstractChannel{Int}
    loop_status::Bool
    conn_status::Bool
end


function show(io::IO, client::Client)
    println("MQTTClient_$(client.id)")
end


function finalizer(client::Client)
    disconnect(client)
    destroy(client.cmosc)
end


"""
    Client(ip::String, port::Int=1883; kwargs...)

Create a client connection to an MQTT broker. Possible key word arguments are:
* id::String = randstring(15)  The id should be unique per connection.
* connectme::Bool = true  Connect immediately if true. If false, you need to manually use *connect(client, ip, port)* and input arguments are not used.
* startloop::Bool = true  If true, and Threads.nthreads()>1, the network loop will be executed regularly after connection.
"""
function Client(ip::String, port::Int=1883; id::String = randstring(15), connectme::Bool = true, startloop::Bool = true)
    # Create mosquitto object
    cobj = Ref{Cvoid}()
    cmosc = mosquitto_new(id, true, cobj)

    # Set callbacks
    #f_message_cb(mos, obj, message) = callback_message(mos, obj, message, id)
    cfunc_message = @cfunction(callback_message, Cvoid, (Ptr{Cmosquitto}, Ptr{Cvoid}, Ptr{CMosquittoMessage}))
    message_callback_set(cmosc, cfunc_message)

    #f_connect_cb(mos, obj, rc) = callback_connect(mos, obj, rc, id)
    cfunc_connect = @cfunction(callback_connect, Cvoid, (Ptr{Cmosquitto}, Ptr{Cvoid}, Cint))
    connect_callback_set(cmosc, cfunc_connect)

    #f_disconnect_cb(mos, obj, rc) = callback_disconnect(mos, obj, rc, id)
    cfunc_disconnect = @cfunction(callback_disconnect, Cvoid, (Ptr{Cmosquitto}, Ptr{Cvoid}, Cint))
    disconnect_callback_set(cmosc, cfunc_disconnect)

    # Create object
    loop_channel = Channel{Int}(1)
    client = Client(id, cmosc, cobj, loop_channel, false, false)

    # Possibly Connect to broker
    if connectme
        flag = connect(client, ip, port)
        flag != 0 && println("Connection to the broker failed")

        # Start loop if it can be started without blocking
        if flag == 0 && startloop && Threads.nthreads()>1
            loop_start(client)
        elseif startloop
            println("Single thread, loop will be blocking, start it manually using loop_start(::Client) or call loop(client) regularly.")
        end
    end

    return client
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
        flag = username_pw_set(client.cmosc, username, password)
        flag != 0 && println("Couldnt set password and username, error $flag")
    end
    flag = connect(client.cmosc, ip; port = port, keepalive = keepalive)
    flag == 0 ? (client.conn_status = true) : println("Connection to broker failed")
    return flag
end


"""
    disconnect(client::Client)
"""
function disconnect(client::Client)
    client.loop_status && loop_stop(client)
    flag = disconnect(client.cmosc)
    flag == 0 && (client.conn_status = false)
    return flag
end


"""
    reconnect(client::Client)
"""
function reconnect(client::Client)
    flag = reconnect(client.cmosc)
    flag == 0 && (client.conn_status = true)
    return flag
end


"""
    publish(client::Client, topic::String, payload; qos::Int = 1, retain::Bool = true)

Publish a message to the broker.
"""
publish(client::Client, topic::String, payload; qos::Int = 1, retain::Bool = true) = publish(client.cmosc, topic, payload; qos = qos, retain = retain)


"""
    subscribe(client::Client, topic::String; qos::Int = 1)

Subscribe to a topic. Received messages will be accessible Mosquitto.messages_channel as a Tuple{String, Vector{Uint8}}.
"""
subscribe(client::Client, topic::String; qos::Int = 1) = subscribe(client.cmosc, topic; qos = qos)


"""
    unsubscribe(client::Client, topic::String)

Unsubscribe from a topic.
"""
unsubscribe(client::Client, topic::String) = unsubscribe(client.cmosc, topic)


"""
    tls_set(client::Client, cafile::String; certfile::String = "", keyfile::String = "")
"""
function tls_set(client::Client, cafile::String; certfile::String = "", keyfile::String = "")
    xor( certfile == "", keyfile == "" ) && throw("You need to either provide both cert and key files, or none of both")
    if certfile == ""
        return tls_set(client.cmosc, cafile, C_NULL, C_NULL, C_NULL, C_NULL)
    else
        return tls_set(client.cmosc, cafile, C_NULL, certfile, keyfile, C_NULL)
    end
end