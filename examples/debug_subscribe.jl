# Reduced set of functionality to reproduce the problem
struct Cmosquitto end

struct CMosquittoMessage
    mid::Cint
	topic::Cstring
	payload::Ptr{Cvoid}
	payloadlen::Cint
    qos::Cint
	retain::Bool
end

const libmosquitto = "libmosquitto.so.1" 

function mosquitto_new(id::String, clean_start::Bool, obj)
    return ccall((:mosquitto_new, libmosquitto), Ptr{Cmosquitto}, (Cstring, Bool, Ptr{Cvoid}), id, clean_start, obj)
end

function connect(client::Ref{Cmosquitto}, host::String; port::Int = 1883, keepalive::Int = 60)
    msg_nr =  ccall((:mosquitto_connect, libmosquitto), Cint, (Ptr{Cmosquitto}, Cstring, Cint, Cint), client, host, port, keepalive)
    return msg_nr
end

function subscribe(client::Ref{Cmosquitto}, sub::String; qos::Int = 1)
    mid = C_NULL
    msg_nr = ccall((:mosquitto_subscribe, libmosquitto), Cint, (Ptr{Cmosquitto}, Ptr{Cint}, Cstring, Cint), client, mid, sub, qos)
    return msg_nr
end

function loop_start(client::Ref{Cmosquitto})
    msg_nr = ccall((:mosquitto_loop_start, libmosquitto), Cint, (Ptr{Cmosquitto},), client)
    return msg_nr
end

function message_callback_set(client::Ref{Cmosquitto}, cfunc)
    ccall((:mosquitto_message_callback_set, libmosquitto), Cvoid, (Ptr{Cmosquitto}, Ptr{Cvoid}), client, cfunc)
    return nothing
end

function connect_callback_set(client::Ref{Cmosquitto}, cfunc)
    msg_nr = ccall((:mosquitto_connect_callback_set, libmosquitto), Cint, (Ptr{Cmosquitto}, Ptr{Cvoid}), client, cfunc)
    return msg_nr
end
# callback functions
jlfunc_message(mos::Ptr{Cmosquitto}, obj::Ptr{Cvoid}, message::Ptr{CMosquittoMessage}) = println("message received")
cfunc_message = @cfunction(jlfunc_message, Cvoid, (Ptr{Cmosquitto}, Ptr{Cvoid}, Ptr{CMosquittoMessage}))

jlfunc_connect(mos::Ptr{Cmosquitto}, obj::Ptr{Cvoid}, Cint) = println("Connection ok")
cfunc_connect = @cfunction(jlfunc_connect, Cvoid, (Ptr{Cmosquitto}, Ptr{Cvoid}, Cint))

## Create a subsription to "test" using a print only callback
# init clib
ccall((:mosquitto_lib_init, libmosquitto), Cint, ())

# create mosquitto object
cobj = Ref{Cvoid}()
testclient = mosquitto_new("testclient", true, cobj)

#message_callback_set(testclient, cfunc_message)
connect_callback_set(testclient, cfunc_connect)

connect(testclient, "localhost")
loop_start(testclient)
# subscribe(testclient, "test")
# starting loop or publishing to "test" here leads to segfault...