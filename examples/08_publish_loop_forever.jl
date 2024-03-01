# This example displays publishing messages fast and also making sure they arrive.
# This requires an async loop, e.g., loop_forever
# and the option "waitcb" when publishing

using Mosquitto, Dates

# connect to a broker
client = Client("test.mosquitto.org", 1883)
topic = "test/julia"

@async loop_forever(client)
for i = 1:20
    message = "Hello World from Julia, send on $(now(UTC)) using the Mosquitto wrapper https://github.com/denglerchr/Mosquitto.jl"
    rc = publish(client, topic, message; qos = 2, waitcb = true) # by setting waitcb = true, the publish function only returns once the broker received the message
    @assert rc == Mosquitto.MosquittoCwrapper.MOSQ_ERR_SUCCESS
    println("published message $i of 20")
end

disconnect(client)
