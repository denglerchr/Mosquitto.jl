# Documentation
# https://mosquitto.org/api/files/mosquitto-h.html#mosquitto_message_callback_set
# https://github.com/eclipse/mosquitto/blob/master/include/mosquitto.h
module Mosquitto

import Base: finalizer, iterate
using Random

include("MosquittoCwrapper/MosquittoCwrapper.jl")
import .MosquittoCwrapper: Cmosquitto, CmosquittoMessage, CmosquittoProperty, lib_version
export MosquittoCwrapper

function __init__()
    mosq_error_code = MosquittoCwrapper.lib_init()
    mosq_error_code != MosquittoCwrapper.MOSQ_ERR_SUCCESS && @warn("Mosquitto init returned error code $mosq_error_code")
    v = lib_version()
    v[1] != 2 || v[2] != 0 || v[3] != 15 && @warn("Found lib version $(v[1]).$(v[2]).$(v[3]), which is different from 2.0.15. Some functionality might not work")
    atexit(MosquittoCwrapper.lib_cleanup)
end

include("callbacks.jl")
include("client.jl")
include("mqtt.jl")
export Client, get_messages_channel, get_connect_channel, get_pub_channel
export connect, reconnect, disconnect
export publish, subscribe, unsubscribe, want_write
export loop, loop_forever, loop_forever2
export tls_set, tls_psk_set
export will_set, will_clear

include("properties_v5.jl")
export PropertyList, create_property_list, add_property!, read_property_list

include("callbacks_v5.jl")
include("client_v5.jl")
include("mqtt_v5.jl")
export Client_v5


end # module
