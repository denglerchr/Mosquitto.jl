struct Client
    cref::CMosquittoClient
    connected::Bool
end

function Client(ip::String, port::Int; keepalive::Int = 60)
    cobj = CMosquittoClient("ID", clean_start = true)
    flag = connect(cobj, ip; port = port, keepalive = keepalive)
    return Client(cobj, flag == 1 )
end

function disconnect(client::Client)
    return disconnect(client.cref)
end

function subscribe!(client::Client, topic::String, channel::AbstractChannel)
    return
end