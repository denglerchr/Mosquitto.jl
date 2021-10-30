struct Cmosquitto end

struct CMosquittoMessage
    mid::Cint
	topic::Cstring
	payload::Ptr{UInt8} # we treat payload as raw bytes
	payloadlen::Cint
    qos::Cint
	retain::Bool
end


function mosquitto_new(id::String, clean_start::Bool, obj)
    return ccall((:mosquitto_new, libmosquitto), Ptr{Cmosquitto}, (Cstring, Bool, Ptr{Cvoid}), id, clean_start, obj)
end


function destroy(client::Ref{Cmosquitto})
    return ccall((:mosquitto_destroy, libmosquitto), Cvoid, (Ptr{Cmosquitto},), client)
end
finalizer(client::Ref{Cmosquitto}) = destroy(client)


function connect(client::Ref{Cmosquitto}, host::String; port::Int = 1883, keepalive::Int = 60)
    return ccall((:mosquitto_connect, libmosquitto), Cint, (Ptr{Cmosquitto}, Cstring, Cint, Cint), client, host, port, keepalive)
end


function reconnect(client::Ref{Cmosquitto})
    ccall((:mosquitto_reconnect, libmosquitto), Cint, (Ptr{Cmosquitto},), client)
end


function disconnect(client::Ref{Cmosquitto})
    return ccall((:mosquitto_disconnect, libmosquitto), Cint, (Ptr{Cmosquitto},), client)
end


function publish(client::Ref{Cmosquitto}, topic::String, payload; qos::Int = 1, retain::Bool = true)
    payloadnew = getbytes(payload)
    payloadlen = length(payloadnew) # dont use sizeof, as payloadnew might be of type "reinterpreted"
    mid = Int[0]
    msg_nr = ccall((:mosquitto_publish, libmosquitto), Cint,
    (Ptr{Cmosquitto}, Ptr{Cint}, Cstring, Cint, Ptr{UInt8}, Cint, Bool), 
    client, mid, topic, payloadlen, payloadnew, qos, retain)
    return msg_nr
end


function subscribe(client::Ref{Cmosquitto}, sub::String; qos::Int = 1)
    mid = zeros(Cint, 1)
    msg_nr = ccall((:mosquitto_subscribe, libmosquitto), Cint, 
    (Ptr{Cmosquitto}, Ptr{Cint}, Cstring, Cint),
    client, mid, sub, qos)
    return msg_nr
end


function unsubscribe(client::Ref{Cmosquitto}, sub::String)
    mid = zeros(Cint, 1)
    msg_nr = ccall((:mosquitto_unsubscribe, libmosquitto), Cint, 
    (Ptr{Cmosquitto}, Ptr{Cint}, Cstring),
    client, mid, sub)
    return msg_nr
end

#= Broken?
function loop_start(client::Ref{Cmosquitto})
    msg_nr = ccall((:mosquitto_loop_start, libmosquitto), Cint, (Ptr{Cmosquitto},), client)
    return msg_nr
end

function loop_stop(client::Ref{Cmosquitto}; force::Bool = false)
    msg_nr = ccall((:mosquitto_loop_stop, libmosquitto), Cint, (Ptr{Cmosquitto}, Bool), client, force)
    return msg_nr
end
=#


function loop_forever(client; timeout::Int = 1000, max_packets::Int = 1)
    return ccall((:mosquitto_loop_forever, libmosquitto), Cint, (Ptr{Cmosquitto}, Cint, Cint), client, timeout, max_packets)
end


function loop(client; timeout::Int = 1000, max_packets::Int = 1)
    return ccall((:mosquitto_loop, libmosquitto), Cint, (Ptr{Cmosquitto}, Cint, Cint), client, timeout, max_packets)
end


function connect_callback_set(client::Ref{Cmosquitto}, cfunc)
    return ccall((:mosquitto_connect_callback_set, libmosquitto), Cvoid, (Ptr{Cmosquitto}, Ptr{Cvoid}), client, cfunc)
end


function message_callback_set(client::Ref{Cmosquitto}, cfunc)
    ccall((:mosquitto_message_callback_set, libmosquitto), Cvoid, (Ptr{Cmosquitto}, Ptr{Cvoid}), client, cfunc)
    return nothing
end


function username_pw_set(client::Ref{Cmosquitto}, username::String, password::String)
    #password != "" && (password = Cstring(C_NULL))
    return ccall((:mosquitto_username_pw_set, libmosquitto), Cint, (Ptr{Cmosquitto}, Cstring, Cstring), client, username, password)
end


function tls_set(client::Ref{Cmosquitto}, cafile, capath, certfile, keyfile, callback::Ptr{Cvoid})
    return ccall((:mosquitto_tls_set, libmosquitto), Cint, (Ptr{Cmosquitto}, Cstring, Cstring, Cstring, Cstring, Ptr{Cvoid}), client, cafile, capath, certfile, keyfile, callback)
end


function lib_version()
    maj = zeros(Int, 1)
    min = zeros(Int, 1)
    rev = zeros(Int, 1)
    ccall((:mosquitto_lib_version, libmosquitto), Cint, (Ptr{Cint}, Ptr{Cint}, Ptr{Cint}), maj, min, rev)
    return maj[1], min[1], rev[1]
end


function lib_cleanup()
    ccall((:mosquitto_lib_cleanup, libmosquitto), Cvoid, ())
end