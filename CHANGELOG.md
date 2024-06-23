## 0.10.0 2024-xx-xx
* Revert change: `loop` will no more reconnect on `MosquittoCwrapper.MOSQ_ERR_NO_CONN`. This lead to reconnects also on intended disconnects.
* add `loop_start` and `loop_stop`

## 0.9.1 - 2024-05-15
* fix `want_write`
* `loop` will also reconnect on `MosquittoCwrapper.MOSQ_ERR_NO_CONN`


## 0.9.0 - 2024-05-01

* `publish`, `subscribe` and `unsubscribe` now return the message id in addition to the mosquitto error code.
* add constructor `Property(name::String, value)`
* add method `add_property!(proplist::PropertyList, prop::Property)`
* define `Base.show` for type `Property`
* `loop_forever` and `loop_forever2` are no longer exported or recommended, as there were reports of problems when calling these.