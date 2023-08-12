function disconnect(client::Client_v5; properties::PropertyList = PropertyList())
    flag = MosquittoCwrapper.disconnect_v5(client.cptr.mosc, properties.mosq_prop.x)
    flag == MosquittoCwrapper.MOSQ_ERR_SUCCESS && (client.conn_status.x = false)
    return flag
end

function will_set(client::Client_v5, topic::String, payload; qos::Int = 1, retain::Bool = false, properties::PropertyList = PropertyList()) 
    return MosquittoCwrapper.will_set_v5(client.cptr.mosc, topic, payload; qos=qos, retain = retain, properties = properties.mosq_prop.x)
end


function publish(client::Client_v5, topic::String, payload; qos::Int = 1, retain::Bool = false, waitcb::Bool = false, properties::PropertyList = PropertyList()) 
    mid = Ref(zero(Cint)) # message id
    rv = MosquittoCwrapper.publish_v5(client.cptr.mosc, mid, topic, payload; qos = qos, retain = retain, properties = properties.mosq_prop.x)

    # possibly wait for message to be sent successfully to broker
    if waitcb && (rv == MosquittoCwrapper.MOSQ_ERR_SUCCESS)
        mid2 = mid.x - Cint(1)
        while mid.x != mid2
            mid2 = take!(client.cbobjs.pub_channel)[1]
        end
    end
    return rv
end

subscribe(client::Client_v5, topic::String; qos::Int = 1, properties::PropertyList = PropertyList()) = MosquittoCwrapper.subscribe_v5(client.cptr.mosc, topic; qos = qos, properties = properties.mosq_prop.x)

unsubscribe(client::Client_v5, topic::String; properties::PropertyList = PropertyList()) = MosquittoCwrapper.unsubscribe_v5(client.cptr.mosc, topic; properties = properties.mosq_prop.x)