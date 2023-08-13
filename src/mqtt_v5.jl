function disconnect(client::Client_v5; properties::PropertyList = PropertyList())
    flag = MosquittoCwrapper.disconnect_v5(client.cptr.mosc, properties.mosq_prop.x)
    flag == MosquittoCwrapper.MOSQ_ERR_SUCCESS && (client.conn_status.x = false)
    return flag
end

function will_set(client::Client_v5, topic::String, payload; qos::Int = 1, retain::Bool = false, properties::PropertyList = PropertyList())
    # Create a copy of properties, as Mosquitto will free by itself
    propcopy = Ref(Ptr{CmosquittoProperty}(C_NULL))
    if properties != C_NULL
        msg1 = MosquittoCwrapper.property_copy_all(propcopy, properties.mosq_prop.x)
        msg1 != MosquittoCwrapper.MOSQ_ERR_SUCCESS && error("Could not copy property list, gor $msg1")
    end

    # Pass copy to will set_v5
    msg2 = MosquittoCwrapper.will_set_v5(client.cptr.mosc, topic, payload; qos=qos, retain = retain, properties = propcopy.x)
    return msg2
end


function publish(client::Client_v5, topic::String, payload; qos::Int = 1, retain::Bool = false, waitcb::Bool = false, properties::PropertyList = PropertyList()) 
    mid = Ref(zero(Cint)) # message id
    rv = MosquittoCwrapper.publish_v5(client.cptr.mosc, mid, topic, payload; qos = qos, retain = retain, properties = properties.mosq_prop.x)

    # possibly wait for message to be sent successfully to broker
    if waitcb && (rv == MosquittoCwrapper.MOSQ_ERR_SUCCESS)
        mid2 = mid.x - Cint(1)
        while mid.x != mid2
            mid2 = take!(get_pub_channel(client))[1]
        end
    end
    return rv
end

subscribe(client::Client_v5, topic::String; qos::Int = 1, properties::PropertyList = PropertyList()) = MosquittoCwrapper.subscribe_v5(client.cptr.mosc, topic; qos = qos, properties = properties.mosq_prop.x)

unsubscribe(client::Client_v5, topic::String; properties::PropertyList = PropertyList()) = MosquittoCwrapper.unsubscribe_v5(client.cptr.mosc, topic; properties = properties.mosq_prop.x)