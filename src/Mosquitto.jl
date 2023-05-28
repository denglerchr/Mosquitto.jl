# Documentation
# https://mosquitto.org/api/files/mosquitto-h.html#mosquitto_message_callback_set
# https://github.com/eclipse/mosquitto/blob/master/include/mosquitto.h
module Mosquitto

import Base: finalizer
import mosquitto_client_jll: libmosquitto
using Random, Libdl


function __init__()
    mosq_error_code = ccall((:mosquitto_lib_init, libmosquitto), Cint, ()) 
    mosq_error_code != 0 && @warn("Mosquitto init returned error code $mosq_error_code")
    v = lib_version()
    v[1] != 2 || v[2] != 0 || v[3] != 15 && @warn("Found lib version $(v[1]).$(v[2]).$(v[3]), which is different from 2.0.15. Some functionality might not work")
    atexit(lib_cleanup)
end

include("helpers.jl")

include("cwrapper.jl")
export lib_version

include("callbacks.jl")
export get_messages_channel, get_connect_channel

include("client.jl")
export Client, connect, reconnect, disconnect, publish, subscribe, unsubscribe, loop, loop_forever, tls_set, tls_psk_set

end # module
