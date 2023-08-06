"""
    connect(client::Client, ip::String, port::Int; kwargs...)

Connect the client to a broker. kwargs are:
* username::String = ""      A username, should one be required
* password::String = ""      A password belonging to the username
* keepalive::Int = 60   Maximal of time the client has to send PINGREQ or a message before disconnection
"""
function connect(client::Client, ip::String, port::Int; username::String = "", password::String = "", keepalive::Int = 60)
    if username != ""
        flag = MosquittoCwrapper.username_pw_set(client.cptr.mosc, username, password)
        flag != MosquittoCwrapper.MOSQ_ERR_SUCCESS && @warn("Couldnt set password and username, error $flag")
    end
    flag = MosquittoCwrapper.connect(client.cptr.mosc, ip; port = port, keepalive = keepalive)
    flag == MosquittoCwrapper.MOSQ_ERR_SUCCESS ? (client.conn_status.x = true) : @warn("Connection to broker failed, error $flag")
    return flag
end


"""
    disconnect(client::Client)

Disconnect the client.
"""
function disconnect(client::Client)
    flag = MosquittoCwrapper.disconnect(client.cptr.mosc)
    flag == MosquittoCwrapper.MOSQ_ERR_SUCCESS && (client.conn_status.x = false)
    return flag
end


"""
    reconnect(client::Client)
"""
function reconnect(client::Client)
    flag = MosquittoCwrapper.reconnect(client.cptr.mosc)
    flag == MosquittoCwrapper.MOSQ_ERR_SUCCESS && (client.conn_status.x = true)
    return flag
end

"""
    will_set(client::Client, topic::String, payload; qos::int = 1, retain::Bool = false)

Must be called before connecting to the broker!
Send a last will to the broker, which will be broadcasted in case
the client disconnects unexpectedly. It will not be broadcasted if
the disconnect is clean using the disconnect function.
"""
will_set(client::Client, topic::String, payload; qos::Int = 1, retain::Bool = false) = MosquittoCwrapper.will_set(client.cptr.mosc, topic, payload; qos=qos, retain = retain)


"""
    will_clear(client::Client)

Remove a previously set will
"""
will_clear(client::Client) = MosquittoCwrapper.will_clear(client.cptr.mosc)


"""
    publish(client::Client, topic::String, payload; kw...)

Publish a message to the broker. Keyword arguments
* qos::Int = 1 : Quality of service
* retain::Bool = false : if true, the broker will store this message
* waitcb = false : if true, wait until the message was received by the broker to return. If set to true, the network loop must run asynchronously, else the function might just block forever.
"""
function publish(client::Client, topic::String, payload; qos::Int = 1, retain::Bool = false, waitcb::Bool = false) 
    mid = Ref(zero(Cint)) # message id
    rv = MosquittoCwrapper.publish(client.cptr.mosc, mid, topic, payload; qos = qos, retain = retain)

    # possibly wait for message to be sent successfully to broker
    if waitcb && (rv == MosquittoCwrapper.MOSQ_ERR_SUCCESS)
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
subscribe(client::Client, topic::String; qos::Int = 1) = MosquittoCwrapper.subscribe(client.cptr.mosc, topic; qos = qos)


"""
    unsubscribe(client::Client, topic::String)

Unsubscribe from a topic.
"""
unsubscribe(client::Client, topic::String) = MosquittoCwrapper.unsubscribe(client.cptr.mosc, topic)


"""
    loop(client::Client; timeout::Int = 1000, ntimes::Int = 1)

Perform a network loop. This will get messages of subscriptions and send published messages.
"""
function loop(client::Client; timeout::Int = 1000, ntimes::Int = 1, autoreconnect::Bool = true) 
    out = MosquittoCwrapper.MOSQ_ERR_INVAL
    for _ = 1:ntimes
        out = MosquittoCwrapper.loop(client.cptr.mosc; timeout = timeout)
        if autoreconnect && out == MosquittoCwrapper.MOSQ_ERR_CONN_LOST
            flag = MosquittoCwrapper.reconnect(client)
            client.conn_status.x = ifelse( flag == MosquittoCwrapper.MOSQ_ERR_SUCCESS, true, false )  
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
loop_forever(client::Client; timeout::Int = 1000) = MosquittoCwrapper.loop_forever(client.cptr.mosc; timeout = timeout, max_packets = 1)


"""
loop_forever2(client::Ref{Cmosquitto}; timeout::Int = 10)

Continuously perform network loop. Reconnecting is handled, and the function returns after 
disconnect(client) is called. This is a slower version of loop_forever, however it works on older Julia versions.
"""
function loop_forever2(client::Client; timeout::Int = 10)
    rc = MosquittoCwrapper.MOSQ_ERR_SUCCESS
    while rc != MOSQ_ERR_NO_CONN
        rc = MosquittoCwrapper.loop(client; timeout = timeout)
        yield()
    end
    return MosquittoCwrapper.MOSQ_ERR_SUCCESS
end


"""
    tls_set(client::Client, cafile::String; certfile::String = "", keyfile::String = "")
"""
function tls_set(client::Client, cafile::String; certfile::String = "", keyfile::String = "")
    xor( certfile == "", keyfile == "" ) && throw("You need to either provide both cert and key files, or none of both")
    if certfile == ""
        return MosquittoCwrapper.tls_set(client.cptr.mosc, cafile, C_NULL, C_NULL, C_NULL, C_NULL)
    else
        return MosquittoCwrapper.tls_set(client.cptr.mosc, cafile, C_NULL, certfile, keyfile, C_NULL)
    end
end


"""
    tls_plk_set(client::Client, psk::String, identity::String, ciphers::Union{Nothing, String})
"""
function tls_psk_set(client::Client, psk::String, identity::String, ciphers::Union{Nothing, String} = nothing)
    return MosquittoCwrapper.tls_psk_set(client.cptr.mosc, psk, identity, ciphers)    
end