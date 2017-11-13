defmodule Bitmex.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Bitmex.Rest.Client, [[name: Bitmex.Rest.Client]],
             max_restarts: Infinity),

      worker(Bitmex.Rest.RateLimiter, [[name: Bitmex.Rest.RateLimiter]],
             max_restarts: Infinity)
    ]

    opts = [strategy: :one_for_one, name: Bitmex.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
