using Mosquitto, Dates

# connect to a broker, also start loop if Threads.nthreads() > 1
client = Client("test.mosquitto.org")

topic = "test"
message = "Hello World from Julia, send on $(now(UTC)) using the Mosquitto wrapper https://github.com/denglerchr/Mosquitto.jl"
publish(client, topic, message; retain = true)
!client.loop_status && loop(client)

disconnect(client)
lib_cleanup()