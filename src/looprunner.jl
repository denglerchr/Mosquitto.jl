"""
    loop(client::Client; timeout::Int = 1000, ntimes::Int = 1)

Perform a network loop. This will get messages of subscriptions and send published messages.
"""
function loop(client::Client; timeout::Int = 1000, ntimes::Int = 1, autoreconnect::Bool = true) 
    out = zero(Cint)
    for _ = 1:ntimes
        out = loop(client.cptr.mosc; timeout = timeout)
        if autoreconnect && out == 4
            flag = reconnect(client)
            client.status.conn_status = ifelse( flag == 0, true, false )  
        end
    end
    return out
end