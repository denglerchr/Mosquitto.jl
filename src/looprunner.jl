"""
    loop(client::Client; timeout::Int = 1000, ntimes::Int = 1)

Perform a network loop. This will get messages of subscriptions and send published messages.
"""
function loop(client::Client; timeout::Int = 1000, ntimes::Int = 1, autoreconnect::Bool = true) 
    out = zero(Cint)
    for _ = 1:ntimes
        out = loop(client.cmosc; timeout = timeout)
        autoreconnect && out == 4 && reconnect(client)
    end
    return out
end


"""
    loop_start(client::Client; autoreconnect::Bool = true)

This function keeps calling the network loop until loop_stop is called.
If only one thread is used, this function will be blocking, else the calls
will be executed on a worker thread.
"""
function loop_start(client::Client; autoreconnect::Bool = true)
    if client.loop_status == true
        println("Loop is already running")
        return 1
    end

    if Threads.nthreads()>1
        client.loop_status = true
        Threads.@spawn loop_runner(client, autoreconnect)
    else
        client.loop_status = true
        loop_forever(client.cmosc)
    end
    return 0
end


"""
    loop_stop(client::Client)

Stop the network loop.
"""
function loop_stop(client::Client)
    if client.loop_status 
        put!(client.loop_channel, 0)
        return fetch(client.loop_channel)
    else
        println("Loop not running")
        return 0
    end
    
end

function loop_runner(client::Client, autoreconnect::Bool)
    while isempty(client.loop_channel)
        msg = copy( loop(client.cmosc) )

        if autoreconnect && msg == Cint(4)
            # case of a disconnect, try reconnecting every 2 seconds
            println("Client disconnected, trying to reconnect...")
            reconnect(client) != 0 && sleep(2)
        elseif msg != Cint(0)
            client.loop_status = false
            println("Loop failed with error $msg")
            return msg
        end
    end
    client.loop_status = false
    return take!(client.loop_channel)
end