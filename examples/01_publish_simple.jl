using Mosquitto, Dates

function main()
    # connect to a broker
    client = Client("test.mosquitto.org")

    topic = "test/julia"
    message = "Hello World from Julia, send on $(now(UTC)) using the Mosquitto wrapper https://github.com/denglerchr/Mosquitto.jl"
    publish(client, topic, message; retain = true)
    loop(client; ntimes = 2)

    disconnect(client)
    loop(client)
    return nothing
end

main()