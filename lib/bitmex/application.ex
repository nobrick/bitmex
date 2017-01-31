defmodule Bitmex.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Bitmex.WS, [])
    ]

    opts = [strategy: :one_for_one, name: Bitmex.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
