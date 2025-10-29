# This example displays publishing messages fast and also making sure they arrive.
# withotut using loop_forever.
# A check for the arrival of the message can be performed by looking at the data in the `pub_channel` of the client.
# Note that for qos == 0, the id would put immediately in the `pub_channel` without waiting for the broker, thus the example wouldnt make sense.

using Mosquitto, Dates

function main()
    # connect to a broker
    client = Client("test.mosquitto.org", 1883)
    topic = "test/julia"
    pubchannel = get_pub_channel(client) # receives feedback once message arrived for 

    # publish messages and wait for broker feedback each time
    for i = 1:20
        message = "Hello World from Julia, send on $(now(UTC)) using the Mosquitto wrapper https://github.com/denglerchr/Mosquitto.jl"  
        rc, message_id = publish(client, topic, message; qos = 1) # we need qos>0 for this to make sense
        @assert rc == Mosquitto.MosquittoCwrapper.MOSQ_ERR_SUCCESS
        while !( message_id in pubchannel.data )
            loop(client)
        end
        println("published message $i of 20")
    end

    disconnect(client)
end

main()