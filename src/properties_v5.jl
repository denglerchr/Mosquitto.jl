"""
    mutable struct PropertyList

Container for mqtt properties. Create using `PropertyList()` or `PropertyList(name, value)` and add items using `add_property!`.
Extract properties using `read_property_list`. 
See help of `MosquittoCwrapper.mqtt5_property` and `MosquittoCwrapper.property_identifier_to_string` for valid inputs.
"""
mutable struct PropertyList
    mosq_prop::Base.RefValue{Ptr{CmosquittoProperty}}

    function PropertyList()
        proplist = new( Ref( Ptr{CmosquittoProperty}(UInt(C_NULL))) )
        
        finalizer(proplist) do x
            MosquittoCwrapper.property_free_all(x.mosq_prop)
            return nothing
        end

        return proplist
    end
end

function PropertyList(name::String, value::T) where {T}
    proplist = PropertyList()
    add_property!(proplist, name, value)
    return proplist
end


struct Property
    name::String
    value::Vector{UInt8}
    prop::MosquittoCwrapper.mqtt5_property
    type::MosquittoCwrapper.mqtt5_property_type

    function Property(prop_ptr::Ptr{CmosquittoProperty})
        # get first identifier if any
        prop_id, success = MosquittoCwrapper.property_identifier(prop_ptr)
        !success && error("Could not create Property from pointer $prop_ptr")
    
        # get name and type as well
        name = MosquittoCwrapper.property_identifier_to_string(prop_id)
        msg, _, type = MosquittoCwrapper.string_to_property_info(name)
        msg != MosquittoCwrapper.MOSQ_ERR_SUCCESS && error("Couldnt find property info for $name")
    
        # get value as byte array
        if type == MosquittoCwrapper.MQTT_PROP_TYPE_STRING_PAIR
            pair, success = MosquittoCwrapper.property_read_string_pair(prop_ptr, prop_id)
            !success && error("Unseccussfull reading of property pair for $prop_id in `property_read_string_pair`")
            name = pair[1]
            val = collect(MosquittoCwrapper.getbytes(pair[2]))
        else
            val = MosquittoCwrapper.property_read_nonpair(prop_ptr, prop_id, type)
        end
    
        return new( name, val, prop_id, type)
    end
end

@inline function isvalidproperty(prop_ptr::Ptr{CmosquittoProperty})
    _, success = MosquittoCwrapper.property_identifier(prop_ptr)
    return success
end

function iterate(proplist::PropertyList)
    !isvalidproperty(proplist.mosq_prop.x) && return nothing
    return Property(proplist.mosq_prop.x), proplist.mosq_prop.x
end

function iterate(proplist::PropertyList, propptr)
    nextprop = MosquittoCwrapper.property_next(propptr)
    !isvalidproperty(nextprop) && return nothing
    return Property(nextprop), nextprop
end

# used in callback, when properties should not be freed
function iterate(propptr::Ptr{CmosquittoProperty})
    !isvalidproperty(propptr) && return nothing
    return Property(propptr), propptr
end

function iterate(propptr::Ptr{CmosquittoProperty}, propptr_state)
    nextprop = MosquittoCwrapper.property_next(propptr_state)
    !isvalidproperty(nextprop) && return nothing
    return Property(nextprop), nextprop
end


"""
add_property!(proplist::PropertyList, name::String, value::T) where {T}

Add a property to an existing property list.
See help of `MosquittoCwrapper.mqtt5_property` and `MosquittoCwrapper.property_identifier_to_string` for valid inputs.
"""
function add_property!(proplist::PropertyList, name::String, value::T) where {T}

    # check name against valid Mosquitto properties
    msg_nr, prop, type = MosquittoCwrapper.string_to_property_info(name)

    # case of no mqtt5_property found => try MQTT_PROP_USER_PROPERTY
    if msg_nr != MosquittoCwrapper.MOSQ_ERR_SUCCESS
        !(T==String) && error("MQTT property $name can only be added as type user property. A user property requires String as value type, got $T")
        prop = MosquittoCwrapper.MQTT_PROP_USER_PROPERTY
        MosquittoCwrapper.property_add_string_pair(proplist.mosq_prop, prop, (name=>value))
        return proplist
    end

    # check value against correct property type
    Trequired = MosquittoCwrapper.get_julia_type(type)
    @assert T == Trequired "Expected type $Trequired for property $prop."


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


"""
read_property_list(props::PropertyList)

Extract a vector of `Property` out of the propertylist.
"""
read_property_list(props::PropertyList) = read_property_list(props.mosq_prop.x)

function read_property_list(propptr::Ptr{CmosquittoProperty})
    Out = Vector{Property}(undef, 0)
    for prop in propptr
        push!(Out, prop)
    end
    return Out
end