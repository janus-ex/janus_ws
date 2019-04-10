[![Hex pm](http://img.shields.io/hexpm/v/janus_ws.svg?style=flat)](https://hex.pm/packages/janus_ws)

For interacting with [Janus WebRTC Gateway](https://github.com/meetecho/janus-gateway) via WebSockets.

#### Example project

https://github.com/janus-ex/janus_ws_example

#### Debugging

Same as in [`:websockex`](https://github.com/Azolo/websockex#debugging):

```elixir
iex(1)> {:ok, client} = Janus.start_link(url: "ws://localhost:8188", registry: some_registry, debug: [:trace])

*DBG* #PID<0.209.0> attempting to connect
*DBG* #PID<0.209.0> sucessfully connected
*DBG* #PID<0.209.0> received cast msg: {:create_session, "Mbcb4i8dMfg", #PID<0.208.0>}
*DBG* #PID<0.209.0> replying from :handle_cast with {:text, "{\"janus\":\"create\",\"transaction\":\"Mbcb4i8dMfg\"}"}
*DBG* #PID<0.209.0> received frame: {:text, "{\"janus\":\"success\",\"transaction\":\"Mbcb4i8dMfg\",\"data\":{\"id\":818647816905897}}"}
*DBG* #PID<0.209.0> sending frame: {:text, "{\"janus\":\"destroy\",\"session_id\":818647816905897,\"transaction\":\"adZA+FChr1M\"}"}
*DBG* #PID<0.209.0> received frame: {:text, "{\"janus\":\"success\",\"session_id\":818647816905897,\"transaction\":\"adZA+FChr1M\"}"}

iex(2)> :sys.trace(client, false)

# ... silence ...

iex(3)> :sys.trace(client, true)

*DBG* #PID<0.209.0> received frame: {:text, "{\"janus\":\"ack\",\"session_id\":7564472917324192,\"transaction\":\"0Al6pqcEPgY\"}"}
*DBG* #PID<0.209.0> sending frame: {:text, "{\"candidate\":{\"completed\":true},\"handle_id\":8087962335175224,\"janus\":\"trickle\",\"session_id\":7564472917324192,\"transaction\":\"2g2m/wtyBRU\"}"}
*DBG* #PID<0.209.0> received frame: {:text, "{\"janus\":\"ack\",\"session_id\":7564472917324192,\"transaction\":\"2g2m/wtyBRU\"}"}
```
