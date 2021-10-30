# Documentation
# https://mosquitto.org/api/files/mosquitto-h.html#mosquitto_message_callback_set
# https://github.com/eclipse/mosquitto/blob/master/include/mosquitto.h
module Mosquitto

import Base.finalizer
using Random, Libdl

# find library
const libmosquitto = @static if Sys.isunix()
    Libdl.find_library("libmosquitto")
elseif Sys.iswindows()
    Libdl.find_library("mosquitto.dll", [raw"C:\Program Files\Mosquitto"])
end

function __init__()
    libmosquitto == "" && throw("Could not find the mosquitto library. If you're sure that it's installed, try adding it to DL_LOAD_PATH and rebuild the package.")
    mosq_error_code = ccall((:mosquitto_lib_init, libmosquitto), Cint, ()) 
    mosq_error_code != 0 && println("Mosquitto init returned error code $mosq_error_code")
    v = lib_version()
    v[1] != 2 || v[2] != 0 && println("Found lib version $(v[1]).$(v[2]), which is different from 2.0. Some functionality might not work")
end

include("helpers.jl")

include("cwrapper.jl")
export lib_version, lib_cleanup

include("client.jl")
export Client, publish, subscribe, unsubscribe, loop, disconnect, reconnect

include("looprunner.jl")
export loop_start, loop_stop

end # module
