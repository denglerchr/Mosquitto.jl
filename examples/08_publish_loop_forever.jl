# This example displays publishing messages fast and also making sure they arrive.
# This requires an async loop, e.g., loop_forever
# and the option "waitcb" when publishing

using Mosquitto, Dates

# connect to a broker, also start loop if Threads.nthreads() > 1
client = Client("test.mosquitto.org")
topic = "test/julia"

@async loop_forever(client)
for i = 1:20
    message = "Hello World from Julia, send on $(now(UTC)) using the Mosquitto wrapper https://github.com/denglerchr/Mosquitto.jl"
    publish(client, topic, message; qos = 1, waitcb = true) # by setting waitcb = true, the publish function only returns once the broker received the message
    println("published message $i of 20")
end

disconnect(client)