"""
    mutable struct PropertyList

Container for mqtt properties. Create using `create_property_list` and add items using `add_property`.
"""
mutable struct PropertyList
    mosq_prop::Ref{Ptr{Cmosquitto_property}}

    function PropertyList()
        proplist = new( Ptr{Cmosquitto_property}(UInt(C_NULL)) )
        finalizer( x->MosquittoCwrapper.property_free_all(x.mosq_prop), proplist)
        return proplist
    end
end


"""
create_property_list(name::String, value::T) where {T}

Create a list containing mqtt properties. Initiates with a single entry, more can be added with
`add_property!`.
"""
function create_property_list(name::String, value::T) where {T}
    proplist = PropertyList()
    add_property!(proplist, name, value)
    return proplist
end


"""
add_property!(proplist::PropertyList, name::String, value::T) where {T}

Add a property to an existing property list
"""
function add_property!(proplist::PropertyList, name::String, value::T) where {T}

    # check name against valid Mosquitto properties
    msg_nr, prop, type = MosquittoCwrapper.string_to_property_info(name)
    msg_nr != MosquittoCwrapper.MOSQ_ERR_SUCCESS && error("Invalid MQTT property name $name. To get a list of valid names, check the enum ?Mosquitto.MosquittoCwrapper.mqtt5_property" )

    # check value against correct property type
    Trequired = MosquittoCwrapper.get_julia_type(type)
    @assert T == Trequired "Exped type $Trequired for property $prop."


    if type == MosquittoCwrapper.MQTT_PROP_TYPE_BYTE
        MosquittoCwrapper.property_add_byte(proplist.mosq_prop, prop, value)

    elseif type == MosquittoCwrapper.MQTT_PROP_TYPE_INT16
        MosquittoCwrapper.property_add_int16(proplist.mosq_prop, prop, value)

    elseif type == MosquittoCwrapper.MQTT_PROP_TYPE_INT32
        MosquittoCwrapper.property_add_int32(proplist.mosq_prop, prop, value)

    elseif type == MosquittoCwrapper.MQTT_PROP_TYPE_VARINT
        MosquittoCwrapper.property_add_varint(proplist.mosq_prop, prop, value)

    elseif type == MosquittoCwrapper.MQTT_PROP_TYPE_BINARY
        MosquittoCwrapper.property_add_binary(proplist.mosq_prop, prop, value)

    elseif type == MosquittoCwrapper.MQTT_PROP_TYPE_STRING
        MosquittoCwrapper.property_add_string(proplist.mosq_prop, prop, value)

    else # MosquittoCwrapper.MQTT_PROP_TYPE_STRING_PAIR
        MosquittoCwrapper.property_add_string_pair(proplist.mosq_prop, prop, value)

    end

    return proplist
end