struct cmosquitto end

struct CMosquittoMessage
    mid::Cint
	topic::Cstring
	payload::Ref{UInt8}
	payloadlen::Cint
    qos::Cint
	retain::Bool
end

mutable struct CMosquittoClient
    cobj::Ref{cmosquitto}
    obj::Ref{Cvoid}
    function CMosquittoClient(id::String, clean_start::Bool, obj)
        cobj = ccall((:mosquitto_new, libmosquitto), Ptr{cmosquitto}, (Cstring, Bool, Ptr{Any}), id, clean_start, obj)
        return new(cobj, obj)
    end
end

CMosquittoClient(id::String; clean_start::Bool = false, obj = Nothing[]) = CMosquittoClient(id, clean_start, obj)


#void mosquitto_destroy(	struct 	mosquitto 	*	mosq	)
function destroy(client::CMosquittoClient)
    ccall((:mosquitto_destroy, libmosquitto), Cvoid, (Ptr{cmosquitto},), client.cobj)
    a.cobj = Ref(cmosquitto())
    return client
end
finalizer(client::CMosquittoClient) = destroy(client)


function connect(client::CMosquittoClient, host::String; port::Int = 1883, keepalive::Int = 60)
    msg_nr =  ccall((:mosquitto_connect, libmosquitto), Cint, (Ptr{cmosquitto}, Cstring, Cint, Cint), client.cobj, host, port, keepalive)
    return msg_nr
end

function disconnect(client::CMosquittoClient)
    ccall((:mosquitto_disconnect, libmosquitto), Cint, (Ptr{cmosquitto},), client.cobj)
    return msg_nr
end

function publish(client::CMosquittoClient, topic::String, payload; qos::Int = 1, retain::Bool = true)
    payloadnew = getbytes(payload)
    payloadlen = sizeof(payloadnew)
    mid = Int[0]
    msg_nr = ccall((:mosquitto_publish, libmosquitto), Cint,
    (Ptr{cmosquitto}, Ptr{Cint}, Cstring, Cint, Ptr{UInt8}, Cint, Bool), 
    client.cobj, mid, topic, payloadlen, payloadnew, qos, retain)
    return msg_nr
end


function subscribe(client::CMosquittoClient, sub::String; qos::Int = 1)
    mid = zeros(Cint, 1)
    msg_nr = ccall((:mosquitto_subscribe, libmosquitto), Cint, 
    (Ptr{cmosquitto}, Ptr{Cint}, Cstring, Cint),
    client.cobj, mid, sub, qos)
    return msg_nr
end

function unsubscribe(client::CMosquittoClient, sub::String)
    mid = zeros(Cint, 1)
    msg_nr = ccall((:mosquitto_unsubscribe, libmosquitto), Cint, 
    (Ptr{cmosquitto}, Ptr{Cint}, Cstring),
    client.cobj, mid, sub)
    return msg_nr
end

function loop_start(client::CMosquittoClient)
    msg_nr = ccall((:mosquitto_loop_start, libmosquitto), Cint, (Ptr{cmosquitto},), client.cobj)
    return msg_nr
end

function loop_stop(client::CMosquittoClient; force::Bool = false)
    msg_nr = ccall((:mosquitto_loop_stop, libmosquitto), Cint, (Ptr{cmosquitto}, Bool), client.cobj, force)
    return msg_nr
end

function connect_callback_set(client::CMosquittoClient, f::Function)
    cfunc = @cfunction($f, Cvoid, (Ptr{cmosquitto}, Ptr{Cvoid}, Cint))
    msg_nr = ccall((:mosquitto_connect_callback_set, libmosquitto), Cint, (Ptr{cmosquitto}, Ptr{Cvoid}), client.cobj, cfunc)
    return msg_nr
end

function message_callback_set(client::CMosquittoClient, f::Function)
    cfunc = @cfunction($f, Cvoid, (Ptr{cmosquitto}, Ptr{Cvoid}, Ptr{CMosquittoMessage}))
    ccall((:mosquitto_message_callback_set, libmosquitto), Cvoid, (Ptr{cmosquitto}, Ptr{Cvoid}), client.cobj, cfunc)
    return nothing
end

function lib_version()
    maj = zeros(Int, 1)
    min = zeros(Int, 1)
    rev = zeros(Int, 1)
    ccall((:mosquitto_lib_version, libmosquitto), Cint, (Ptr{Cint}, Ptr{Cint}, Ptr{Cint}), maj, min, rev)
    return maj[1], min[1], rev[1]
end

function cleanup()
    ccall((:mosquitto_lib_cleanup, libmosquitto), Cint, ())
end