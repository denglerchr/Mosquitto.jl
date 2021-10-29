"""
    loop(client::Client; timeout::Int = 2000)

Perform a network loop. This will get messages of subscriptions and send published messages.
"""
loop(client::Client; timeout::Int = 2000) =  loop(client.cmosc; timeout = timeout)


"""
    loop_start(client::Client)

This function keeps calling the network loop until loop_stop is called.
If only one thread is used, this function will be blocking, else the calls
will be executed on a worker thread.
"""
function loop_start(client::Client; autoreconnect::Bool = true)
    if Threads.nthreads()>1
        Threads.@spawn loop_runner(client, autoreconnect)
        client.loop_status = true
    else
        client.loop_status = true
        loop_forever(client.cmosc)
    end
    return 0
end

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
    while true
        if !isempty(client.loop_channel)
            client.loop_status = false
            return take!(client.loop_channel)
        end
        
        msg = loop(client.cmosc)

        if msg == 4 && autoreconnect
            # case of a disconnect, try reconnecting every 2 seconds
            reconnect(client.cmosc) != 0 && sleep(2)
            println("Client disconnected, trying to reconnect...")
        elseif msg != 0
            client.loop_status = false
            println("Loop failed with error $msg")
            return msg
        end
    end
end