using HttpServer, Lazy

import Base.Meta.isexpr

export @app, serve

# `App` is just a box which allows the server to be
# redefined on the fly.
# In general these methods provide a simple way to
# get up and running, but aren't meant to be comprehensive.

type App
  warez
end

macro app(def)
  @assert isexpr(def, :(=))
  name, warez = def.args
  warez = isexpr(warez, :tuple) ? Expr(:call, :mux, map(esc, warez.args)...) : warez
  quote
    if isdefined($(Expr(:quote, name)))
      $(esc(name)).warez = $warez
    else
      const $(esc(name)) = App($warez)
    end
    nothing
  end
end

function http_handler(app::App)
  handler = HttpHandler((req, res) -> app.warez(req))
  handler.events["error"]  = (client, error) -> println(error)
  handler.events["listen"] = (port)          -> println("Listening on $port...")
  return handler
end

function ws_handler(app::App)
  handler = WebSocketHandler((req, client) -> app.warez((req, client)))
  return handler
end

const default_host = ip"127.0.0.1"
const default_port = 8000

function serve(s::Server; host = default_host, port = default_port)
  @async @errs run(s, host=host, port=port)
  return
end

serve(h::App; host = default_host, port = default_port) =
  serve(Server(http_handler(h)), host=host, port=port)

serve(h::App, w::App; host = default_host, port = default_port) =
  serve(Server(http_handler(h), ws_handler(w)), host=host, port=port)
