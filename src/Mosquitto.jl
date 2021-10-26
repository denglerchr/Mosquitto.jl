# Documentation
# https://mosquitto.org/api/files/mosquitto-h.html#mosquitto_message_callback_set
# https://github.com/eclipse/mosquitto/blob/master/include/mosquitto.h
module Mosquitto

import Base.finalizer
using Random

const libmosquitto = "libmosquitto.so.1" #/lib/x86_64-linux-gnu/

function __init__()
    mosq_error_code = ccall((:mosquitto_lib_init, libmosquitto), Cint, ()) 
    mosq_error_code != 0 && println("Mosquitto init returned error code $mosq_error_code")
end

include("helpers.jl")

include("cwrapper.jl")
export lib_version

include("client.jl")
export Client, publish, subscribe!, startloop, stoploop, disconnect

end # module
