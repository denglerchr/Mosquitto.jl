# Reduced set of functionality to reproduce the problem
struct Cmosquitto end

const libmosquitto = "libmosquitto.so.1" 

function mosquitto_new(id::String, clean_start::Bool, obj)
    return ccall((:mosquitto_new, libmosquitto), Ptr{Cmosquitto}, (Cstring, Bool, Ptr{Cvoid}), id, clean_start, obj)
end

function connect(client::Ptr{Cmosquitto}, host::String; port::Int = 1883, keepalive::Int = 60)
    msg_nr =  ccall((:mosquitto_connect, libmosquitto), Cint, (Ptr{Cmosquitto}, Cstring, Cint, Cint), client, host, port, keepalive)
    return msg_nr
end

function loop_start(client::Ptr{Cmosquitto})
    msg_nr = ccall((:mosquitto_loop_start, libmosquitto), Cint, (Ptr{Cmosquitto},), client)
    return msg_nr
end

function connect_callback_set(client::Ptr{Cmosquitto}, cfunc)
    msg_nr = ccall((:mosquitto_connect_callback_set, libmosquitto), Cint, (Ptr{Cmosquitto}, Ptr{Cvoid}), client, cfunc)
    return msg_nr
end

# callback function
callback_connect_jl(mos::Ptr{Cmosquitto}, obj::Ptr{Cvoid}, unused::Cint) = println("Connection ok")
callback_connect_c = @cfunction(callback_connect_jl, Cvoid, (Ptr{Cmosquitto}, Ptr{Cvoid}, Cint))

## Script
# init clib
ccall((:mosquitto_lib_init, libmosquitto), Cint, ())

# create mosquitto object
cobj = Ref{Cvoid}()
testclient = mosquitto_new("testclient", true, cobj)

#message_callback_set(testclient, cfunc_message)
connect_callback_set(testclient, callback_connect_c)

connect(testclient, "localhost")
loop_start(testclient) # segfault