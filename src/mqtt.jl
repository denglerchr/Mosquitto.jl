"""
    connect(client::AbstractClient, ip::String, port::Int; kwargs...)

Connect the client to a broker. kwargs are:
* username::String = ""      A username, should one be required
* password::String = ""      A password belonging to the username
* keepalive::Int = 60   Maximal of time the client has to send PINGREQ or a message before disconnection
"""
function connect(client::AbstractClient, ip::String, port::Int; username::String = "", password::String = "", keepalive::Int = 60)
    if username != ""
        flag = MosquittoCwrapper.username_pw_set(client.cptr.mosc, username, password)
        flag != MosquittoCwrapper.MOSQ_ERR_SUCCESS && @warn("Couldnt set password and username, error $flag")
    end
    flag = MosquittoCwrapper.connect(client.cptr.mosc, ip; port = port, keepalive = keepalive)
    flag == MosquittoCwrapper.MOSQ_ERR_SUCCESS ? (client.conn_status.x = true) : @warn("Connection to broker failed, error $flag")
    return flag
end


"""
    disconnect(client::AbstractClient)

Disconnect the client. Keyword argument, only available with Client_v5:
* properties = Properties() : a list of properties to append to the message.
"""
function disconnect(client::Client)
    flag = MosquittoCwrapper.disconnect(client.cptr.mosc)
    flag == MosquittoCwrapper.MOSQ_ERR_SUCCESS && (client.conn_status.x = false)
    return flag
end


"""
    reconnect(client::AbstractClient)
"""
function reconnect(client::AbstractClient)
    flag = MosquittoCwrapper.reconnect(client.cptr.mosc)
    flag == MosquittoCwrapper.MOSQ_ERR_SUCCESS && (client.conn_status.x = true)
    return flag
end

"""
    will_set(client::AbstractClient, topic::String, payload; kw...)

Must be called before connecting to the broker!
Send a last will to the broker, which will be broadcasted in case the client disconnects unexpectedly. It will not be broadcasted if
the disconnect is clean using the disconnect function.

Keyword arguments:
* qos::int = 1
* retain::Bool = false

Additional keyword arguments, only available on Client_v5:
* properties = Properties() : a list of properties to append to the message.
"""
will_set(client::Client, topic::String, payload; qos::Int = 1, retain::Bool = false) = MosquittoCwrapper.will_set(client.cptr.mosc, topic, payload; qos=qos, retain = retain)


"""
    will_clear(client::AbstractClient)

Remove a previously set will.
"""
will_clear(client::AbstractClient) = MosquittoCwrapper.will_clear(client.cptr.mosc)


"""
    publish(client::AbstractClient, topic::String, payload; kw...)

Publish a message to the broker. Returns the Mosquitto error code and the message id.

Keyword arguments:
* qos::Int = 1 : Quality of service
* retain::Bool = false : if true, the broker will store this message
* waitcb = false : if true, wait until the message was received by the broker to return. If set to true, the network loop must run asynchronously, else the function might just block forever.

Only available on Client_v5:
* properties = Properties() : a list of properties to append to the message.
"""
function publish(client::Client, topic::String, payload; qos::Int = 1, retain::Bool = false, waitcb::Bool = false) 
    mid = Ref(zero(Cint)) # message id
    rv = MosquittoCwrapper.publish(client.cptr.mosc, mid, topic, payload; qos = qos, retain = retain)

    # possibly wait for message to be sent successfully to broker
    if waitcb && (rv == MosquittoCwrapper.MOSQ_ERR_SUCCESS)
        mid2 = mid.x - Cint(1)
        while mid.x != mid2
            mid2 = take!(get_pub_channel(client))
        end
    end
    return rv, mid.x
end


"""
    subscribe(client::AbstractClient, topic::String; kw...)

Subscribe to a topic. Received messages will be accessible Mosquitto.messages_channel as a Tuple{String, Vector{Uint8}}.
Returns the Mosquitto error code and the message id.

Keyword arguments:
* qos::Int = 1

Additional keyword arguments, only available on Client_v5:
* properties = Properties() : a list of properties to append to the message.
"""
function subscribe(client::Client, topic::String; qos::Int = 1)
    mid = Ref(zero(Cint))
    rv = MosquittoCwrapper.subscribe(client.cptr.mosc, mid, topic; qos = qos)
    return rv, mid.x
end


"""
    unsubscribe(client::AbstractClient, topic::String)

Unsubscribe from a topic.
Returns the Mosquitto error code and the message id.

Additional keyword argument, only available on Client_v5:
* properties = Properties() : a list of properties to append to the message.
"""
function unsubscribe(client::Client, topic::String)
    mid = Ref(zero(Cint))
    rv = MosquittoCwrapper.unsubscribe(client.cptr.mosc, mid, topic)
    return rv, mid.x
end


"""
    loop(client::AbstractClient; timeout::Int = 1000, ntimes::Int = 1, autoreconnect::Bool = true)

Perform a network loop. This will get messages of subscriptions and send published messages.
"""
function loop(client::AbstractClient; timeout::Int = 1000, ntimes::Int = 1, autoreconnect::Bool = true) 
    out = MosquittoCwrapper.MOSQ_ERR_INVAL
    for _ = 1:ntimes
        out = MosquittoCwrapper.loop(client.cptr.mosc; timeout = timeout)
        if autoreconnect && out == MosquittoCwrapper.MOSQ_ERR_CONN_LOST
            flag = reconnect(client)
            client.conn_status.x = ifelse( flag == MosquittoCwrapper.MOSQ_ERR_SUCCESS, true, false )  
        end
    end
    return out
end


"""
    loop_start(client::AbstractClient)

Call this once to start a new C thread to process network traffic. This provides an alternative to repeatedly calling mosquitto_loop yourself.
"""
function loop_start(client::AbstractClient)
    return MosquittoCwrapper.loop_start(client.cptr.mosc)
end


"""
    loop_stop(client::AbstractClient; force::Bool = false)

Call this once to stop the network thread previously created with `loop_start`. 
This call will block until the network thread finishes. For the network thread to end, you must have previously called `disconnect` or have set the force parameter to true.
"""
function loop_stop(client::AbstractClient; force::Bool = false)
    return MosquittoCwrapper.loop_stop(client.cptr.mosc; force = force)
end


"""
    loop_forever(client::AbstractClient; timeout::Int = 1000)

Continuously perform network loop. Reconnecting is handled, and the function returns after 
disconnect(client) is called. Calls the mosquitto C library using @threadcall to allow
asynchronous execution.
This function segfaults on older Julia versions, a Mosquitto.loop_forever2(client) functions can
be used for a worse performance, but more stable version of it.
"""
loop_forever(client::AbstractClient; timeout::Int = 1000) = MosquittoCwrapper.loop_forever(client.cptr.mosc; timeout = timeout, max_packets = 1)


"""
    loop_forever2(client::AbstractClient; timeout::Int = 10)

Continuously perform network loop. Reconnecting is handled, and the function returns after 
disconnect(client) is called. This is a slower version of loop_forever, however it works on older Julia versions.
"""
function loop_forever2(client::AbstractClient; timeout::Int = 10)
    rc = MosquittoCwrapper.MOSQ_ERR_SUCCESS
    while rc != MosquittoCwrapper.MOSQ_ERR_NO_CONN
        rc = loop(client; timeout = timeout)
        yield()
    end
    return MosquittoCwrapper.MOSQ_ERR_SUCCESS
end


"""
    want_write(client::AbstractClient)

Returns true if there is data ready to be written on the socket.
"""
want_write(client::AbstractClient) = (MosquittoCwrapper.want_write(client.cptr.mosc) & 0x01) == 0x01


"""
    tls_set(client::AbstractClient, cafile::String; certfile::String = "", keyfile::String = "")
"""
function tls_set(client::AbstractClient, cafile::String; certfile::String = "", keyfile::String = "")
    xor( certfile == "", keyfile == "" ) && throw("You need to either provide both cert and key files, or none of both")
    if certfile == ""
        return MosquittoCwrapper.tls_set(client.cptr.mosc, cafile, C_NULL, C_NULL, C_NULL, C_NULL)
    else
        return MosquittoCwrapper.tls_set(client.cptr.mosc, cafile, C_NULL, certfile, keyfile, C_NULL)
    end
end


"""
    tls_plk_set(client::AbstractClient, psk::String, identity::String, ciphers::Union{Nothing, String})
"""
function tls_psk_set(client::AbstractClient, psk::String, identity::String, ciphers::Union{Nothing, String} = nothing)
    return MosquittoCwrapper.tls_psk_set(client.cptr.mosc, psk, identity, ciphers)    
end
