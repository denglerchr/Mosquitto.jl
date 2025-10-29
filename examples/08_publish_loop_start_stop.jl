# This example displays publishing messages fast and also making sure they arrive.
# This requires the option "waitcb" when publishing
# combined with qos>0

using Mosquitto, Dates

function main()
    # connect to a broker
    client = Client("test.mosquitto.org", 1883)
    topic = "test/julia"
    loop_start(client)
    
    # publish messages and wait for broker feedback each time
    for i = 1:20
        message = "Hello World from Julia, send on $(now(UTC)) using the Mosquitto wrapper https://github.com/denglerchr/Mosquitto.jl"  
        rc, _ = publish(client, topic, message; qos = 2, waitcb = true) # by setting waitcb = true, the publish function only returns once the broker received the message
        @assert rc == Mosquitto.MosquittoCwrapper.MOSQ_ERR_SUCCESS
        println("published message $i of 20")
    end

    disconnect(client)
    return loop_stop(client)
end

main()