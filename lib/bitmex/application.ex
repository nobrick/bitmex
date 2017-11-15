defmodule Bitmex.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Bitmex.Websocket.Parser, [[name: Bitmex.Websocket.Parser]],
             max_restarts: :infinity, restart: :permanent),

      worker(Bitmex.Rest.Client, [[name: Bitmex.Rest.Client]],
             max_restarts: :infinity, restart: :permanent),

      worker(Bitmex.Rest.RateLimiter, [[name: Bitmex.Rest.RateLimiter]],
             max_restarts: :infinity, restart: :permanent)
    ]

    opts = [strategy: :one_for_one, name: Bitmex.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
