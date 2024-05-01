struct CmosquittoProperty end

# structs from mqtt_protocol.h

"""
    @enum mqtt5_property::Cint

Maps valid mqtt properties. You can call `MosquittoCwrapper.property_identifier_to_string` on its values to
get the string representation. Defined in `mqtt_protocol.h`.

* `MQTT_PROP_PAYLOAD_FORMAT_INDICATOR` = 1		 #  Byte :				PUBLISH, Will Properties */
* `MQTT_PROP_MESSAGE_EXPIRY_INTERVAL` = 2		 #  4 byte int :			PUBLISH, Will Properties */
* `MQTT_PROP_CONTENT_TYPE` = 3					 #  UTF-8 string :		PUBLISH, Will Properties */
* `MQTT_PROP_RESPONSE_TOPIC` = 8				 #  UTF-8 string :		PUBLISH, Will Properties */
* `MQTT_PROP_CORRELATION_DATA` = 9				 #  Binary Data :		PUBLISH, Will Properties */
* `MQTT_PROP_SUBSCRIPTION_IDENTIFIER` = 11		 #  Variable byte int :	PUBLISH, SUBSCRIBE */
* `MQTT_PROP_SESSION_EXPIRY_INTERVAL` = 17		 #  4 byte int :			CONNECT, CONNACK, DISCONNECT */
* `MQTT_PROP_ASSIGNED_CLIENT_IDENTIFIER` = 18	 #  UTF-8 string :		CONNACK */
* `MQTT_PROP_SERVER_KEEP_ALIVE` = 19			 #  2 byte int :			CONNACK */
* `MQTT_PROP_AUTHENTICATION_METHOD` = 21		 #  UTF-8 string :		CONNECT, CONNACK, AUTH */
* `MQTT_PROP_AUTHENTICATION_DATA` = 22			 #  Binary Data :		CONNECT, CONNACK, AUTH */
* `MQTT_PROP_REQUEST_PROBLEM_INFORMATION` = 23	 #  Byte :				CONNECT */
* `MQTT_PROP_WILL_DELAY_INTERVAL` = 24			 #  4 byte int :			Will properties */
* `MQTT_PROP_REQUEST_RESPONSE_INFORMATION` = 25  #  Byte :				CONNECT */
* `MQTT_PROP_RESPONSE_INFORMATION` = 26		 	 #  UTF-8 string :		CONNACK */
* `MQTT_PROP_SERVER_REFERENCE` = 28			 	 #  UTF-8 string :		CONNACK, DISCONNECT */
* `MQTT_PROP_REASON_STRING` = 31				 #  UTF-8 string :		All except Will properties */
* `MQTT_PROP_RECEIVE_MAXIMUM` = 33				 #  2 byte int :			CONNECT, CONNACK */
* `MQTT_PROP_TOPIC_ALIAS_MAXIMUM` = 34			 #  2 byte int :			CONNECT, CONNACK */
* `MQTT_PROP_TOPIC_ALIAS` = 35					 #  2 byte int :			PUBLISH */
* `MQTT_PROP_MAXIMUM_QOS` = 36					 #  Byte :				CONNACK */
* `MQTT_PROP_RETAIN_AVAILABLE` = 37			 	 #  Byte :				CONNACK */
* `MQTT_PROP_USER_PROPERTY` = 38				 #  UTF-8 string pair :	All */
* `MQTT_PROP_MAXIMUM_PACKET_SIZE` = 39			 #  4 byte int :			CONNECT, CONNACK */
* `MQTT_PROP_WILDCARD_SUB_AVAILABLE` = 40		 #  Byte :				CONNACK */
* `MQTT_PROP_SUBSCRIPTION_ID_AVAILABLE` = 41	 #  Byte :				CONNACK */
* `MQTT_PROP_SHARED_SUB_AVAILABLE` = 42			 #  Byte :				CONNACK */
"""
@enum mqtt5_property::Cint begin
    MQTT_PROP_PAYLOAD_FORMAT_INDICATOR = 1 #  Byte :				PUBLISH, Will Properties */
    MQTT_PROP_MESSAGE_EXPIRY_INTERVAL = 2 #  4 byte int :			PUBLISH, Will Properties */
    MQTT_PROP_CONTENT_TYPE = 3 #  UTF-8 string :		PUBLISH, Will Properties */
    MQTT_PROP_RESPONSE_TOPIC = 8 #  UTF-8 string :		PUBLISH, Will Properties */
    MQTT_PROP_CORRELATION_DATA = 9 #  Binary Data :		PUBLISH, Will Properties */
    MQTT_PROP_SUBSCRIPTION_IDENTIFIER = 11 #  Variable byte int :	PUBLISH, SUBSCRIBE */
    MQTT_PROP_SESSION_EXPIRY_INTERVAL = 17 #  4 byte int :			CONNECT, CONNACK, DISCONNECT */
    MQTT_PROP_ASSIGNED_CLIENT_IDENTIFIER = 18 #  UTF-8 string :		CONNACK */
    MQTT_PROP_SERVER_KEEP_ALIVE = 19 #  2 byte int :			CONNACK */
    MQTT_PROP_AUTHENTICATION_METHOD = 21 #  UTF-8 string :		CONNECT, CONNACK, AUTH */
    MQTT_PROP_AUTHENTICATION_DATA = 22 #  Binary Data :		CONNECT, CONNACK, AUTH */
    MQTT_PROP_REQUEST_PROBLEM_INFORMATION = 23 #  Byte :				CONNECT */
    MQTT_PROP_WILL_DELAY_INTERVAL = 24 #  4 byte int :			Will properties */
    MQTT_PROP_REQUEST_RESPONSE_INFORMATION = 25 #  Byte :				CONNECT */
    MQTT_PROP_RESPONSE_INFORMATION = 26 #  UTF-8 string :		CONNACK */
    MQTT_PROP_SERVER_REFERENCE = 28 #  UTF-8 string :		CONNACK, DISCONNECT */
    MQTT_PROP_REASON_STRING = 31 #  UTF-8 string :		All except Will properties */
    MQTT_PROP_RECEIVE_MAXIMUM = 33 #  2 byte int :			CONNECT, CONNACK */
    MQTT_PROP_TOPIC_ALIAS_MAXIMUM = 34 #  2 byte int :			CONNECT, CONNACK */
    MQTT_PROP_TOPIC_ALIAS = 35 #  2 byte int :			PUBLISH */
    MQTT_PROP_MAXIMUM_QOS = 36 #  Byte :				CONNACK */
    MQTT_PROP_RETAIN_AVAILABLE = 37 #  Byte :				CONNACK */
    MQTT_PROP_USER_PROPERTY = 38 #  UTF-8 string pair :	All */
    MQTT_PROP_MAXIMUM_PACKET_SIZE = 39 #  4 byte int :			CONNECT, CONNACK */
    MQTT_PROP_WILDCARD_SUB_AVAILABLE = 40 #  Byte :				CONNACK */
    MQTT_PROP_SUBSCRIPTION_ID_AVAILABLE = 41 #  Byte :				CONNACK */
    MQTT_PROP_SHARED_SUB_AVAILABLE = 42 #  Byte :				CONNACK */
end


"""
Possible types of the values that go together with a mqtt5_property.
"""
@enum mqtt5_property_type begin
    MQTT_PROP_TYPE_BYTE = 1
    MQTT_PROP_TYPE_INT16 = 2
    MQTT_PROP_TYPE_INT32 = 3
    MQTT_PROP_TYPE_VARINT = 4
    MQTT_PROP_TYPE_BINARY = 5
    MQTT_PROP_TYPE_STRING = 6
    MQTT_PROP_TYPE_STRING_PAIR = 7
end

"""
 Enum: mqtt5_sub_options
  Options for use with MQTTv5 subscriptions.
 
  MQTT_SUB_OPT_NO_LOCAL - with this option set, if this client publishes to
  a topic to which it is subscribed, the broker will not publish the
  message back to the client.
 
  MQTT_SUB_OPT_RETAIN_AS_PUBLISHED - with this option set, messages
  published for this subscription will keep the retain flag as was set by
  the publishing client. The default behaviour without this option set has
  the retain flag indicating whether a message is fresh/stale.
 
  MQTT_SUB_OPT_SEND_RETAIN_ALWAYS - with this option set, pre-existing
  retained messages are sent as soon as the subscription is made, even
  if the subscription already exists. This is the default behaviour, so
  it is not necessary to set this option.
 
  MQTT_SUB_OPT_SEND_RETAIN_NEW - with this option set, pre-existing retained
  messages for this subscription will be sent when the subscription is made,
  but only if the subscription does not already exist.
 
  MQTT_SUB_OPT_SEND_RETAIN_NEVER - with this option set, pre-existing
  retained messages will never be sent for this subscription.
"""
@enum mqtt5_sub_options begin
    MQTT_SUB_OPT_NO_LOCAL = Cint(0x04)
    MQTT_SUB_OPT_RETAIN_AS_PUBLISHED = Cint(0x08)
    MQTT_SUB_OPT_SEND_RETAIN_ALWAYS = Cint(0x00)
    MQTT_SUB_OPT_SEND_RETAIN_NEW = Cint(0x10)
    MQTT_SUB_OPT_SEND_RETAIN_NEVER = Cint(0x20)
end


"""
Possible commands, can be used in mosquitto_property_check_all.
"""
@enum mqtt_cmd begin
    CMD_CONNECT = Cint(0x10)
    CMD_CONNACK = Cint(0x20)
    CMD_PUBLISH = Cint(0x30)
    CMD_PUBACK = Cint(0x40)
    CMD_PUBREC = Cint(0x50)
    CMD_PUBREL = Cint(0x60)
    CMD_PUBCOMP = Cint(0x70)
    CMD_SUBSCRIBE = Cint(0x80)
    CMD_SUBACK = Cint(0x90)
    CMD_UNSUBSCRIBE = Cint(0xA0)
    CMD_UNSUBACK = Cint(0xB0)
    CMD_PINGREQ = Cint(0xC0)
    CMD_PINGRESP = Cint(0xD0)
    CMD_DISCONNECT = Cint(0xE0)
    CMD_AUTH = Cint(0xF0)
    CMD_WILL = Cint(0x100) # only Mosquitto
end


# map the mqtt5_property_type to a corresponding Julia type
@inline function get_julia_type(t::mqtt5_property_type)
    mqtt5_property_type_map = (UInt8, UInt16, UInt32, UInt32, Vector{UInt8}, String, Pair{String,String})
    return mqtt5_property_type_map[Integer(t)]
end

# Will

function will_set_v5(client::Ref{Cmosquitto}, topic::String, payload;
    qos::Int=1, retain::Bool=false, properties::Ref{CmosquittoProperty}=C_NULL)
    payloadnew = getbytes(payload)
    payloadlen = length(payloadnew) # dont use sizeof, as payloadnew might be of type "reinterpreted"
    msg_nr = ccall((:mosquitto_will_set_v5, libmosquitto), Cint,
        (Ptr{Cmosquitto}, Cstring, Cint, Ptr{UInt8}, Cint, Bool, Ptr{CmosquittoProperty}),
        client, topic, payloadlen, payloadnew, qos, retain, properties)
    return mosq_err_t(msg_nr)
end

# Connecting, reconnecting, disconnecting

function disconnect_v5(client::Ref{Cmosquitto}, properties::Ref{CmosquittoProperty})
    msg_nr = ccall((:mosquitto_disconnect, libmosquitto), Cint, (Ptr{Cmosquitto}, Ptr{CmosquittoProperty}), client, properties)
    return mosq_err_t(msg_nr)
end

# Publishing, subscribing, unsubscribing

function publish_v5(client::Ref{Cmosquitto}, mid::Ref{Cint}, topic::String, payload;
    qos::Int=1, retain::Bool=true, properties::Ref{CmosquittoProperty}=C_NULL)

    payloadnew = getbytes(payload)
    payloadlen = length(payloadnew) # dont use sizeof, as payloadnew might be of type "reinterpreted"
    msg_nr = ccall((:mosquitto_publish_v5, libmosquitto), Cint,
        (Ptr{Cmosquitto}, Ptr{Cint}, Cstring, Cint, Ptr{UInt8}, Cint, Bool, Ptr{CmosquittoProperty}),
        client, mid, topic, payloadlen, payloadnew, qos, retain, properties)
    return mosq_err_t(msg_nr)
end

function subscribe_v5(client::Ref{Cmosquitto}, mid::Ref{Cint}, sub::String; qos::Int=1, properties::Ref{CmosquittoProperty}=C_NULL)
    options = Cint(MQTT_SUB_OPT_SEND_RETAIN_ALWAYS) # default, can be combined using or

    msg_nr = ccall((:mosquitto_subscribe_v5, libmosquitto), Cint,
        (Ptr{Cmosquitto}, Ptr{Cint}, Cstring, Cint, Cint, Ptr{CmosquittoProperty}),
        client, mid, sub, qos, options, properties)
    return mosq_err_t(msg_nr)
end


function unsubscribe_v5(client::Ref{Cmosquitto}, mid::Ref{Cint}, sub::String; properties::Ref{CmosquittoProperty}=C_NULL)
    msg_nr = ccall((:mosquitto_unsubscribe_v5, libmosquitto), Cint,
        (Ptr{Cmosquitto}, Ptr{Cint}, Cstring, Ptr{CmosquittoProperty}),
        client, mid, sub, properties)
    return mosq_err_t(msg_nr)
end

# Callbacks

function connect_v5_callback_set(client::Ref{Cmosquitto}, cfunc)
    return ccall((:mosquitto_connect_v5_callback_set, libmosquitto), Cvoid, (Ptr{Cmosquitto}, Ptr{Cvoid}), client, cfunc)
end


function disconnect_v5_callback_set(client::Ref{Cmosquitto}, cfunc)
    return ccall((:mosquitto_disconnect_v5_callback_set, libmosquitto), Cvoid, (Ptr{Cmosquitto}, Ptr{Cvoid}), client, cfunc)
end


function publish_v5_callback_set(client::Ref{Cmosquitto}, cfunc)
    return ccall((:mosquitto_publish_v5_callback_set, libmosquitto), Cvoid, (Ptr{Cmosquitto}, Ptr{Cvoid}), client, cfunc)
end


function message_v5_callback_set(client::Ref{Cmosquitto}, cfunc)
    ccall((:mosquitto_message_v5_callback_set, libmosquitto), Cvoid, (Ptr{Cmosquitto}, Ptr{Cvoid}), client, cfunc)
    return nothing
end

# Utility functions

# Properties

function property_add_byte(proplist::Ref{Ptr{CmosquittoProperty}}, identifier::mqtt5_property, value::UInt8)
    msg_nr = ccall((:mosquitto_property_add_byte, libmosquitto), Cint,
        (Ptr{Ptr{CmosquittoProperty}}, Cint, UInt8),
        proplist, Cint(identifier), value)
    return mosq_err_t(msg_nr)
end


function property_add_int16(proplist::Ref{Ptr{CmosquittoProperty}}, identifier::mqtt5_property, value::UInt16)
    msg_nr = ccall((:mosquitto_property_add_int16, libmosquitto), Cint,
        (Ptr{Ptr{CmosquittoProperty}}, Cint, UInt16),
        proplist, Cint(identifier), value)
    return mosq_err_t(msg_nr)
end


function property_add_int32(proplist::Ref{Ptr{CmosquittoProperty}}, identifier::mqtt5_property, value::UInt32)
    msg_nr = ccall((:mosquitto_property_add_int32, libmosquitto), Cint,
        (Ptr{Ptr{CmosquittoProperty}}, Cint, UInt32),
        proplist, Cint(identifier), value)
    return mosq_err_t(msg_nr)
end


function property_add_varint(proplist::Ref{Ptr{CmosquittoProperty}}, identifier::mqtt5_property, value::UInt32)
    msg_nr = ccall((:mosquitto_property_add_varint, libmosquitto), Cint,
        (Ptr{Ptr{CmosquittoProperty}}, Cint, UInt32),
        proplist, Cint(identifier), value)
    return mosq_err_t(msg_nr)
end


function property_add_binary(proplist::Ref{Ptr{CmosquittoProperty}}, identifier::mqtt5_property, value::Vector{UInt8})

    len = length(value)
    @assert len < typemax(UInt16)

    msg_nr = ccall((:mosquitto_property_add_binary, libmosquitto), Cint,
        (Ptr{Ptr{CmosquittoProperty}}, Cint, Ptr{Cvoid}, UInt16),
        proplist, Cint(identifier), value, UInt16(len))
    return mosq_err_t(msg_nr)
end


function property_add_string(proplist::Ref{Ptr{CmosquittoProperty}}, identifier::mqtt5_property, value::String)
    msg_nr = ccall((:mosquitto_property_add_string, libmosquitto), Cint,
        (Ptr{Ptr{CmosquittoProperty}}, Cint, Cstring),
        proplist, Cint(identifier), value)
    return mosq_err_t(msg_nr)
end


function property_add_string_pair(proplist::Ref{Ptr{CmosquittoProperty}}, identifier::mqtt5_property, pair::Pair{String,String})
    name = pair[1]
    value = pair[2]
    msg_nr = ccall((:mosquitto_property_add_string_pair, libmosquitto), Cint,
        (Ptr{Ptr{CmosquittoProperty}}, Cint, Cstring, Cstring),
        proplist, Cint(identifier), name, value)
    return mosq_err_t(msg_nr)
end


"""
    property_identifier(prop::Ptr{CmosquittoProperty})

Returns the `mqtt5_property`` of the property together with a success flag.
If success is false, the mqtt5_property is invalid
"""
function property_identifier(prop::Ptr{CmosquittoProperty})
    msg = ccall((:mosquitto_property_identifier, libmosquitto), Cint, (Ptr{CmosquittoProperty},), prop)
    if msg == zero(Cint)
        prop_out = mqtt5_property(one(Cint))
        success = false
    else
        prop_out = mqtt5_property(msg)
        success = true
    end
    return prop_out, success
end


function property_next(prop::Ptr{CmosquittoProperty})
    return ccall((:mosquitto_property_next, libmosquitto), Ptr{CmosquittoProperty}, (Ptr{CmosquittoProperty},), prop)
end


function property_read_byte(prop::Ptr{CmosquittoProperty}, identifier::mqtt5_property; onfail::UInt8=zero(UInt8))
    valref = Ref(onfail)
    ptr = ccall((:mosquitto_property_read_byte, libmosquitto), Ptr{CmosquittoProperty}, (Ptr{CmosquittoProperty}, Cint, Ptr{UInt8}, Bool), prop, Integer(identifier), valref, false)
    success = (ptr != C_NULL)
    return valref.x, success
end


function property_read_int16(prop::Ptr{CmosquittoProperty}, identifier::mqtt5_property; onfail::UInt16=zero(UInt16))
    valref = Ref(onfail)
    ptr = ccall((:mosquitto_property_read_int16, libmosquitto), Ptr{CmosquittoProperty}, (Ptr{CmosquittoProperty}, Cint, Ptr{UInt16}, Bool), prop, Integer(identifier), valref, false)
    success = (ptr != C_NULL)
    return valref.x, success
end


function property_read_int32(prop::Ptr{CmosquittoProperty}, identifier::mqtt5_property; onfail::UInt32=zero(UInt32))
    valref = Ref(onfail)
    ptr = ccall((:mosquitto_property_read_int32, libmosquitto), Ptr{CmosquittoProperty}, (Ptr{CmosquittoProperty}, Cint, Ptr{UInt32}, Bool), prop, Integer(identifier), valref, false)
    success = (ptr != C_NULL)
    return valref.x, success
end


function property_read_varint(prop::Ptr{CmosquittoProperty}, identifier::mqtt5_property; onfail::UInt32=zero(UInt32))
    valref = Ref(onfail)
    ptr = ccall((:mosquitto_property_read_varint, libmosquitto), Ptr{CmosquittoProperty}, (Ptr{CmosquittoProperty}, Cint, Ptr{UInt32}, Bool), prop, Integer(identifier), valref, false)
    success = (ptr != C_NULL)
    return valref.x, success
end


function property_read_binary(prop::Ptr{CmosquittoProperty}, identifier::mqtt5_property)
    valref = Ref{Ptr{UInt8}}(C_NULL)
    lenref = Ref{UInt16}(C_NULL)
    ptr = ccall((:mosquitto_property_read_binary, libmosquitto),
        Ptr{CmosquittoProperty}, (Ptr{CmosquittoProperty}, Cint, Ptr{Ptr{UInt8}}, Ref{UInt16}, Bool),
        prop, Integer(identifier), valref, lenref, false)
    if ptr == C_NULL
        bytevec = UInt8[]
        success = false
    else
        bytevec = [unsafe_load(valref.x, i) for i = 1:lenref.x]
        Libc.free(valref.x)
        success = true
    end
    return bytevec, success
end


function property_read_string(prop::Ptr{CmosquittoProperty}, identifier::mqtt5_property)
    valref = Ref{Cstring}(C_NULL)
    ptr = ccall((:mosquitto_property_read_string, libmosquitto), Ptr{CmosquittoProperty}, (Ptr{CmosquittoProperty}, Cint, Ptr{Cstring}, Bool), prop, Integer(identifier), valref, false)
    if ptr == C_NULL
        strout = ""
        success = false
    else
        strout = unsafe_string(valref.x)
        Libc.free(valref.x)
        success = true
    end
    return strout, success
end


function property_read_string_pair(prop::Ptr{CmosquittoProperty}, identifier::mqtt5_property)
    nameref = Ref{Cstring}(C_NULL)
    valref = Ref{Cstring}(C_NULL)
    ptr = ccall((:mosquitto_property_read_string_pair, libmosquitto), Ptr{CmosquittoProperty},
        (Ptr{CmosquittoProperty}, Cint, Ptr{Cstring}, Ptr{Cstring}, Bool),
        prop, Integer(identifier), nameref, valref, false)
    if ptr == C_NULL
        pair_out = ("" => "")
        success = false
    else
        # TODO do we have to free memory here?
        name_out = unsafe_string(nameref.x)
        val_out = unsafe_string(valref.x)
        Libc.free(nameref.x)
        Libc.free(valref.x)
        pair_out = (name_out => val_out)
        success = true
    end
    return pair_out, success
end


"""
Not a Mosquitto C function, but convenience to always return a Vector{UInt8}.
"""
function property_read_nonpair(prop::Ptr{CmosquittoProperty}, identifier::mqtt5_property, type::mqtt5_property_type)::Vector{UInt8}
    if type == MQTT_PROP_TYPE_BYTE
        val, success = property_read_byte(prop, identifier)
        Out = UInt8[val]
    elseif type == MQTT_PROP_TYPE_INT16
        val, success = property_read_int16(prop, identifier)
        Out = collect(getbytes(val))
    elseif type == MQTT_PROP_TYPE_INT32
        val, success = property_read_int32(prop, identifier)
        Out = collect(getbytes(val))
    elseif type == MQTT_PROP_TYPE_VARINT
        val, success = property_read_varint(prop, identifier)
        Out = collect(getbytes(val))
    elseif type == MQTT_PROP_TYPE_BINARY
        val, success = property_read_binary(prop, identifier)
        Out = val
    elseif type == MQTT_PROP_TYPE_STRING
        val, success = property_read_string(prop, identifier)
        Out = collect(getbytes(val))
    elseif type == MQTT_PROP_TYPE_STRING_PAIR
        error("A pair type should not be read using `property_read_nonpair`")
    else
        error("Unreachable reached in `property_read_nonpair`")
    end
    !success && error("Unseccussfull reading property for identifier $identifier of type $type.")
    return Out
end



function property_free_all(proplist::Ref{Ptr{CmosquittoProperty}})
    return ccall((:mosquitto_property_free_all, libmosquitto), Cvoid, (Ptr{Ptr{CmosquittoProperty}},), proplist)
end


function property_copy_all(dest::Ref{Ptr{CmosquittoProperty}}, src::Ptr{CmosquittoProperty})
    msg = ccall((:mosquitto_property_copy_all, libmosquitto), Cint, (Ptr{Ptr{CmosquittoProperty}}, Ptr{CmosquittoProperty}), dest, src)
    return mosq_err_t(msg)
end


function property_check_all(command::mqtt_cmd, properties::Ptr{CmosquittoProperty})
    msg = ccall((:mosquitto_property_check_all, libmosquitto), Cint, (Cint, Ptr{CmosquittoProperty}), Cint(command), properties)
    return mosq_err_t(msg)
end

function property_identifier_to_string(identifier::mqtt5_property)
    cstr = ccall((:mosquitto_property_identifier_to_string, libmosquitto), Cstring, (Cint,), Integer(identifier))
    if cstr == C_NULL
        return "Not found"
    else
        str_out = unsafe_string(cstr) # not allowed to free cstr, or segfault
        return str_out
    end
end


"""
	string_to_property_info(propname::String)

This function behaves a bit differently from plain mosquitto one.
It returns a Tuple{mosq_err_t, mqtt5_property, mqtt5_property_type} and
the mosq_err_t has to be checked for MOSQ_ERR_SUCCESS, else the other 2
values are not correct.
"""
function string_to_property_info(propname::String)
    identifier = Ref(one(Cint))
    type = Ref(one(Cint))
    msg_nr = ccall((:mosquitto_string_to_property_info, libmosquitto), Cint, (Cstring, Ptr{Cint}, Ptr{Cint}), propname, identifier, type)
    return mosq_err_t(msg_nr), mqtt5_property(identifier.x), mqtt5_property_type(type.x)
end