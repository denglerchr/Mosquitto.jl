module Mosquitto

import Base.finalizer
const libmosquitto = "libmosquitto.so.1" #/lib/x86_64-linux-gnu/

function __init__()
    mosq_error_code = ccall((:mosquitto_lib_init, libmosquitto), Cint, ()) 
    mosq_error_code != 0 && println("Mosquitto init returned error code $mosq_error_code")
end


include("cwrapper.jl")
export lib_version

include("client.jl")

end # module
