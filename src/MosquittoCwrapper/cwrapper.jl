struct Cmosquitto end

struct CmosquittoMessage
    mid::Cint
	topic::Cstring
	payload::Ptr{UInt8} # we treat payload as raw bytes
	payloadlen::Cint
    qos::Cint
	retain::Bool
end

# Error codes from mosquitto.h
@enum mosq_err_t::Cint begin
	MOSQ_ERR_AUTH_CONTINUE = -4
	MOSQ_ERR_NO_SUBSCRIBERS = -3
	MOSQ_ERR_SUB_EXISTS = -2
	MOSQ_ERR_CONN_PENDING = -1
	MOSQ_ERR_SUCCESS = 0
	MOSQ_ERR_NOMEM = 1
	MOSQ_ERR_PROTOCOL = 2
	MOSQ_ERR_INVAL = 3
	MOSQ_ERR_NO_CONN = 4
	MOSQ_ERR_CONN_REFUSED = 5
	MOSQ_ERR_NOT_FOUND = 6
	MOSQ_ERR_CONN_LOST = 7
	MOSQ_ERR_TLS = 8
	MOSQ_ERR_PAYLOAD_SIZE = 9
	MOSQ_ERR_NOT_SUPPORTED = 10
	MOSQ_ERR_AUTH = 11
	MOSQ_ERR_ACL_DENIED = 12
	MOSQ_ERR_UNKNOWN = 13
	MOSQ_ERR_ERRNO = 14
	MOSQ_ERR_EAI = 15
	MOSQ_ERR_PROXY = 16
	MOSQ_ERR_PLUGIN_DEFER = 17
	MOSQ_ERR_MALFORMED_UTF8 = 18
	MOSQ_ERR_KEEPALIVE = 19
	MOSQ_ERR_LOOKUP = 20
	MOSQ_ERR_MALFORMED_PACKET = 21
	MOSQ_ERR_DUPLICATE_PROPERTY = 22
	MOSQ_ERR_TLS_HANDSHAKE = 23
	MOSQ_ERR_QOS_NOT_SUPPORTED = 24
	MOSQ_ERR_OVERSIZE_PACKET = 25
	MOSQ_ERR_OCSP = 26
	MOSQ_ERR_TIMEOUT = 27
	MOSQ_ERR_RETAIN_NOT_SUPPORTED = 28
	MOSQ_ERR_TOPIC_ALIAS_INVALID = 29
	MOSQ_ERR_ADMINISTRATIVE_ACTION = 30
	MOSQ_ERR_ALREADY_EXISTS = 31
end

@enum mosq_opt_t::Cint begin
	MOSQ_OPT_PROTOCOL_VERSION = 1
	MOSQ_OPT_SSL_CTX = 2
	MOSQ_OPT_SSL_CTX_WITH_DEFAULTS = 3
	MOSQ_OPT_RECEIVE_MAXIMUM = 4
	MOSQ_OPT_SEND_MAXIMUM = 5
	MOSQ_OPT_TLS_KEYFORM = 6
	MOSQ_OPT_TLS_ENGINE = 7
	MOSQ_OPT_TLS_ENGINE_KPASS_SHA1 = 8
	MOSQ_OPT_TLS_OCSP_REQUIRED = 9
	MOSQ_OPT_TLS_ALPN = 10
	MOSQ_OPT_TCP_NODELAY = 11
	MOSQ_OPT_BIND_ADDRESS = 12
	MOSQ_OPT_TLS_USE_OS_CERTS = 13
end

const MQTT_PROTOCOL_V31 = Cint(3)
const MQTT_PROTOCOL_V311 = Cint(4)
const MQTT_PROTOCOL_V5 = Cint(5)

# Library version, init, and cleanup

function lib_version()
    maj = zeros(Int, 1)
    min = zeros(Int, 1)
    rev = zeros(Int, 1)
    ccall((:mosquitto_lib_version, libmosquitto), Cint, (Ptr{Cint}, Ptr{Cint}, Ptr{Cint}), maj, min, rev)
    return maj[1], min[1], rev[1]
end

function lib_init()
    msg_nr = ccall((:mosquitto_lib_init, libmosquitto), Cint, ()) 
    return mosq_err_t(msg_nr)
end

function lib_cleanup()
    ccall((:mosquitto_lib_cleanup, libmosquitto), Cvoid, ())
end

# Client creation, destruction, and reinitialisation

function mosquitto_new(id::String, clean_session::Bool, obj)
    return ccall((:mosquitto_new, libmosquitto), Ptr{Cmosquitto}, (Cstring, Bool, Ptr{Cvoid}), id, clean_session, obj)
end


function destroy(client::Ref{Cmosquitto})
    return ccall((:mosquitto_destroy, libmosquitto), Cvoid, (Ptr{Cmosquitto},), client)
end

# Will

function will_set(client::Ref{Cmosquitto}, topic::String, payload; qos::Int=1, retain::Bool = false)
    payloadnew = getbytes(payload)
    payloadlen = length(payloadnew) # dont use sizeof, as payloadnew might be of type "reinterpreted"
    msg_nr = ccall((:mosquitto_will_set, libmosquitto), Cint,
                    (Ptr{Cmosquitto}, Cstring, Cint, Ptr{UInt8}, Cint, Bool), 
                    client, topic, payloadlen, payloadnew, qos, retain)
    return mosq_err_t(msg_nr)
end

function will_clear(client::Ref{Cmosquitto})
    msg_nr = ccall((:mosquitto_will_clear, libmosquitto), Cint, (Ptr{Cmosquitto},), client)
    return mosq_err_t(msg_nr)
end

# Username and password

function username_pw_set(client::Ref{Cmosquitto}, username::String, password::String)
    #password != "" && (password = Cstring(C_NULL))
    msg_nr = ccall((:mosquitto_username_pw_set, libmosquitto), Cint, (Ptr{Cmosquitto}, Cstring, Cstring), client, username, password)
    return mosq_err_t(msg_nr)
end

# Connecting, reconnecting, disconnecting

function connect(client::Ref{Cmosquitto}, host::String; port::Int = 1883, keepalive::Int = 60)
    msg_nr = ccall((:mosquitto_connect, libmosquitto), Cint, (Ptr{Cmosquitto}, Cstring, Cint, Cint), client, host, port, keepalive)
    return mosq_err_t(msg_nr)
end


function reconnect(client::Ref{Cmosquitto})
    msg_nr = ccall((:mosquitto_reconnect, libmosquitto), Cint, (Ptr{Cmosquitto},), client)
    return mosq_err_t(msg_nr)
end


function disconnect(client::Ref{Cmosquitto})
    msg_nr = ccall((:mosquitto_disconnect, libmosquitto), Cint, (Ptr{Cmosquitto},), client)
    return mosq_err_t(msg_nr)
end

# Publishing, subscribing, unsubscribing

function publish(client::Ref{Cmosquitto}, mid::Ref{Cint}, topic::String, payload; qos::Int = 1, retain::Bool = true)
    payloadnew = getbytes(payload)
    payloadlen = length(payloadnew) # dont use sizeof, as payloadnew might be of type "reinterpreted"
    msg_nr = ccall((:mosquitto_publish, libmosquitto), Cint,
                    (Ptr{Cmosquitto}, Ptr{Cint}, Cstring, Cint, Ptr{UInt8}, Cint, Bool), 
                    client, mid, topic, payloadlen, payloadnew, qos, retain)
    return mosq_err_t(msg_nr)
end


function subscribe(client::Ref{Cmosquitto}, mid::Ref{Cint}, sub::String; qos::Int = 1)
    msg_nr = ccall((:mosquitto_subscribe, libmosquitto), Cint, 
    (Ptr{Cmosquitto}, Ptr{Cint}, Cstring, Cint),
    client, mid, sub, qos)
    return mosq_err_t(msg_nr)
end


function unsubscribe(client::Ref{Cmosquitto}, mid::Ref{Cint}, sub::String)
    msg_nr = ccall((:mosquitto_unsubscribe, libmosquitto), Cint, 
                    (Ptr{Cmosquitto}, Ptr{Cint}, Cstring),
                    client, mid, sub)
    return mosq_err_t(msg_nr)
end

# Network loop (managed by libmosquitto)

function loop_start(client::Ref{Cmosquitto})
    msg_nr = ccall((:mosquitto_loop_start, libmosquitto), Cint, (Ptr{Cmosquitto},), client)
    return mosq_err_t(msg_nr)
end


function loop_stop(client::Ref{Cmosquitto}; force::Bool = false)
    msg_nr = ccall((:mosquitto_loop_stop, libmosquitto), Cint, (Ptr{Cmosquitto}, Bool), client, force)
    return mosq_err_t(msg_nr)
end


function loop_forever(client::Ref{Cmosquitto}; timeout::Int = 1000, max_packets::Int = 1)
    msg_nr = @threadcall((:mosquitto_loop_forever, libmosquitto), Cint, (Ptr{Cmosquitto}, Cint, Cint), client, timeout, max_packets)
    return mosq_err_t(msg_nr)
end


function loop(client::Ref{Cmosquitto}; timeout::Int = 1000, max_packets::Int = 1)
    msg_nr = ccall((:mosquitto_loop, libmosquitto), Cint, (Ptr{Cmosquitto}, Cint, Cint), client, timeout, max_packets)
    return mosq_err_t(msg_nr)
end

# Network loop (helper functions)

function want_write(client::Ref{Cmosquitto})
    # Cuchar is equivalent to bool in C, see https://docs.julialang.org/en/v1/manual/calling-c-and-fortran-code/
    return ccall((:mosquitto_want_write, libmosquitto), Cuchar, (Ptr{Cmosquitto},), client)
end

# Client options

function int_option(client::Ref{Cmosquitto}, option::mosq_opt_t, value::Cint)
    msg_nr = ccall((:mosquitto_int_option, libmosquitto), Cint, (Ptr{Cmosquitto}, Cint, Cint), client, Integer(option), value)
    return mosq_err_t(msg_nr)
end


function string_option(client::Ref{Cmosquitto}, option::mosq_opt_t, value::String)
    msg_nr = ccall((:mosquitto_string_option, libmosquitto), Cint, (Ptr{Cmosquitto}, Cint, Cstring), client, Integer(option), value)
    return mosq_err_t(msg_nr)
end

# TLS support


function tls_set(client::Ref{Cmosquitto}, cafile, capath, certfile, keyfile, callback::Ptr{Cvoid})
    msg_nr = ccall((:mosquitto_tls_set, libmosquitto), Cint, (Ptr{Cmosquitto}, Cstring, Cstring, Cstring, Cstring, Ptr{Cvoid}), client, cafile, capath, certfile, keyfile, callback)
    return mosq_err_t(msg_nr)
end


function tls_psk_set(client::Ref{Cmosquitto}, psk::String, identity::String, ciphers::Nothing)
    msg_nr = ccall((:mosquitto_tls_psk_set, libmosquitto), Cint, (Ptr{Cmosquitto}, Cstring, Cstring, Cstring), client, psk, identity, C_NULL)
    return mosq_err_t(msg_nr)
end


function tls_psk_set(client::Ref{Cmosquitto}, psk::String, identity::String, ciphers::String)
    msg_nr = ccall((:mosquitto_tls_psk_set, libmosquitto), Cint, (Ptr{Cmosquitto}, Cstring, Cstring, Cstring), client, psk, identity, ciphers)
    return mosq_err_t(msg_nr)
end

# Callbacks

function connect_callback_set(client::Ref{Cmosquitto}, cfunc)
    return ccall((:mosquitto_connect_callback_set, libmosquitto), Cvoid, (Ptr{Cmosquitto}, Ptr{Cvoid}), client, cfunc)
end


function disconnect_callback_set(client::Ref{Cmosquitto}, cfunc)
    return ccall((:mosquitto_disconnect_callback_set, libmosquitto), Cvoid, (Ptr{Cmosquitto}, Ptr{Cvoid}), client, cfunc)
end


function publish_callback_set(client::Ref{Cmosquitto}, cfunc)
    return ccall((:mosquitto_publish_callback_set, libmosquitto), Cvoid, (Ptr{Cmosquitto}, Ptr{Cvoid}), client, cfunc)
end


function message_callback_set(client::Ref{Cmosquitto}, cfunc)
    ccall((:mosquitto_message_callback_set, libmosquitto), Cvoid, (Ptr{Cmosquitto}, Ptr{Cvoid}), client, cfunc)
    return nothing
end
